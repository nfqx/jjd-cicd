/**
 * Generic, read-only SOQL action for Flow.
 *
 * The output is a generic SObject collection. The custom Flow property editor
 * maps U__records to the object configured in outputObjectApiName.
 *
 * Security:
 * - SELECT queries only
 * - AccessLevel.USER_MODE
 * - with sharing
 * - no FOR UPDATE/VIEW/REFERENCE, ALL ROWS or access-mode override
 * - hard row limit
 */
public with sharing class GenericSoqlGetRecordsAction {
    private static final Integer DEFAULT_MAX_ROWS = 2000;
    private static final Integer ABSOLUTE_MAX_ROWS = 10000;
    private static final Integer FIELDS_ALL_MAX_ROWS = 200;
    private static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE =
        Schema.getGlobalDescribe();
    private static final Map<String, String> OBJECT_NAMES_BY_LOWER =
        buildObjectNameIndex();

    private static final Set<String> ALLOWED_BIND_NAMES = new Set<String>{
        'recordId',
        'textValue1',
        'textValue2',
        'numberValue1',
        'dateValue1',
        'dateTimeValue1',
        'booleanValue1',
        'maxRows'
    };

    public class Request {
        @InvocableVariable(
            required=true
            label='SOQL-Abfrage'
            description='Nur eine SELECT-Abfrage. Beispiel: SELECT Id,Name FROM Account WHERE ParentId = :recordId'
        )
        public String soqlQuery;

        @InvocableVariable(
            required=true
            label='Ausgabeobjekt (API-Name)'
            description='Objekt hinter dem äußeren FROM, z. B. Account. Bestimmt den Typ der Flow-Collection.'
        )
        public String outputObjectApiName;

        @InvocableVariable(
            label='Maximale Datensatzanzahl'
            description='Standard: 2.000; Maximum: 10.000. Ohne LIMIT ergänzt die Action automatisch ein Limit.'
        )
        public Integer maxRows;

        @InvocableVariable(
            label='Bind: recordId'
            description='Optionale ID aus dem Flow. Im SOQL mit :recordId verwenden.'
        )
        public Id recordId;

        @InvocableVariable(
            label='Bind: textValue1'
            description='Optionaler Textwert. Im SOQL mit :textValue1 verwenden.'
        )
        public String textValue1;

        @InvocableVariable(
            label='Bind: textValue2'
            description='Optionaler zweiter Textwert. Im SOQL mit :textValue2 verwenden.'
        )
        public String textValue2;

        @InvocableVariable(
            label='Bind: numberValue1'
            description='Optionaler Zahlenwert. Im SOQL mit :numberValue1 verwenden.'
        )
        public Decimal numberValue1;

        @InvocableVariable(
            label='Bind: dateValue1'
            description='Optionales Datum. Im SOQL mit :dateValue1 verwenden.'
        )
        public Date dateValue1;

        @InvocableVariable(
            label='Bind: dateTimeValue1'
            description='Optionales Datum/Uhrzeit. Im SOQL mit :dateTimeValue1 verwenden.'
        )
        public Datetime dateTimeValue1;

        @InvocableVariable(
            label='Bind: booleanValue1'
            description='Optionaler Boolean-Wert. Im SOQL mit :booleanValue1 verwenden.'
        )
        public Boolean booleanValue1;
    }

    public class Result {
        @InvocableVariable(
            label='records'
            description='Alle gefundenen Datensätze als typisierte Flow-Record-Collection.'
        )
        public List<SObject> records;

        @InvocableVariable(label='Anzahl gefundener Datensätze')
        public Integer recordCount;

        @InvocableVariable(label='Angewendetes Maximum')
        public Integer appliedMaxRows;

        @InvocableVariable(label='Objekt-API-Name')
        public String objectApiName;

        public Result() {
            records = new List<SObject>();
            recordCount = 0;
        }
    }

    public class SoqlConfigurationException extends Exception {}

    private class ParsedRequest {
        Integer originalIndex;
        String preparedQuery;
        String objectApiName;
        Schema.SObjectType objectType;
        Integer effectiveMaxRows;
        Map<String, Object> binds;
        String signature;
    }

    private class QueryAnalysis {
        String rootObjectToken;
        Boolean containsFieldsFunction = false;
        Integer explicitNumericLimit;
        TopLevelToken limitToken;
        TopLevelToken offsetToken;
        List<TopLevelToken> tokens;
    }

    private class TopLevelToken {
        String value;
        Integer startIndex;
        Integer endIndex;

        TopLevelToken(String value, Integer startIndex, Integer endIndex) {
            this.value = value;
            this.startIndex = startIndex;
            this.endIndex = endIndex;
        }
    }

    @InvocableMethod(
        label='SOQL Get Records'
        description='Führt eine sichere, lesende SOQL-Abfrage aus und liefert alle Treffer als auswählbare Record-Collection.'
        configurationEditor='c-soql-get-records-editor'
    )
    public static List<Result> execute(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<Result>();
        }

        List<Result> results = new List<Result>();
        Map<String, List<ParsedRequest>> requestsBySignature =
            new Map<String, List<ParsedRequest>>();

        for (Integer i = 0; i < requests.size(); i++) {
            results.add(new Result());
            ParsedRequest parsed = parseRequest(requests[i], i);
            if (!requestsBySignature.containsKey(parsed.signature)) {
                requestsBySignature.put(parsed.signature, new List<ParsedRequest>());
            }
            requestsBySignature.get(parsed.signature).add(parsed);
        }

        for (List<ParsedRequest> equalRequests : requestsBySignature.values()) {
            ParsedRequest representative = equalRequests[0];
            List<SObject> queryRecords = runQuery(representative);

            for (ParsedRequest parsed : equalRequests) {
                Result result = results[parsed.originalIndex];
                result.records = new List<SObject>();
                result.records.addAll(queryRecords);
                result.recordCount = queryRecords.size();
                result.appliedMaxRows = parsed.effectiveMaxRows;
                result.objectApiName = parsed.objectApiName;
            }
        }

        return results;
    }

    private static List<SObject> runQuery(ParsedRequest parsed) {
        if (Limits.getQueries() >= Limits.getLimitQueries()) {
            throw new SoqlConfigurationException(
                'Die Salesforce-Grenze für SOQL-Abfragen ist bereits erreicht.'
            );
        }

        Integer remainingRows = Limits.getLimitQueryRows() - Limits.getQueryRows();
        if (remainingRows <= 0) {
            throw new SoqlConfigurationException(
                'Die Salesforce-Grenze für gelesene Datensätze ist bereits erreicht.'
            );
        }

        List<SObject> records;
        try {
            records = Database.queryWithBinds(
                parsed.preparedQuery,
                parsed.binds,
                AccessLevel.USER_MODE
            );
        } catch (Exception ex) {
            throw new SoqlConfigurationException(
                'SOQL-Abfrage fehlgeschlagen: ' + ex.getMessage()
            );
        }

        for (SObject recordItem : records) {
            if (recordItem.getSObjectType() != parsed.objectType) {
                throw new SoqlConfigurationException(
                    'Die Abfrage liefert ' +
                    recordItem.getSObjectType().getDescribe().getName() +
                    ', im Flow wurde aber ' + parsed.objectApiName + ' ausgewählt.'
                );
            }
        }
        return records;
    }

    private static ParsedRequest parseRequest(Request request, Integer requestIndex) {
        if (request == null) {
            throw new SoqlConfigurationException(
                'Request ' + (requestIndex + 1) + ' ist leer.'
            );
        }
        if (String.isBlank(request.soqlQuery)) {
            throw new SoqlConfigurationException('SOQL-Abfrage darf nicht leer sein.');
        }
        if (String.isBlank(request.outputObjectApiName)) {
            throw new SoqlConfigurationException(
                'Ausgabeobjekt (API-Name) darf nicht leer sein.'
            );
        }

        Integer maxRows = request.maxRows == null
            ? DEFAULT_MAX_ROWS
            : request.maxRows;
        if (maxRows < 1 || maxRows > ABSOLUTE_MAX_ROWS) {
            throw new SoqlConfigurationException(
                'Maximale Datensatzanzahl muss zwischen 1 und ' +
                ABSOLUTE_MAX_ROWS + ' liegen.'
            );
        }

        String query = request.soqlQuery.trim();
        QueryAnalysis analysis = analyzeQuery(query);

        String canonicalObjectName = OBJECT_NAMES_BY_LOWER.get(
            request.outputObjectApiName.trim().toLowerCase()
        );
        if (canonicalObjectName == null) {
            throw new SoqlConfigurationException(
                'Objekt "' + request.outputObjectApiName + '" wurde nicht gefunden.'
            );
        }
        Schema.SObjectType objectType = GLOBAL_DESCRIBE.get(canonicalObjectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        if (!objectDescribe.isQueryable()) {
            throw new SoqlConfigurationException(
                'Objekt ' + canonicalObjectName + ' ist nicht per SOQL abfragbar.'
            );
        }
        if (!analysis.rootObjectToken.equalsIgnoreCase(canonicalObjectName)) {
            throw new SoqlConfigurationException(
                'Das äußere FROM verwendet ' + analysis.rootObjectToken +
                ', als Ausgabeobjekt wurde aber ' + canonicalObjectName + ' gewählt.'
            );
        }

        Integer effectiveMaxRows = analysis.containsFieldsFunction
            ? Math.min(maxRows, FIELDS_ALL_MAX_ROWS)
            : maxRows;
        if (analysis.explicitNumericLimit != null) {
            if (analysis.explicitNumericLimit > effectiveMaxRows) {
                throw new SoqlConfigurationException(
                    'Die Abfrage enthält LIMIT ' + analysis.explicitNumericLimit +
                    ', erlaubt sind für diese Action höchstens ' + effectiveMaxRows + '.'
                );
            }
            effectiveMaxRows = analysis.explicitNumericLimit;
        }
        String preparedQuery = applyRowLimit(query, analysis);

        Map<String, Object> binds = new Map<String, Object>{
            'recordId' => request.recordId,
            'textValue1' => request.textValue1,
            'textValue2' => request.textValue2,
            'numberValue1' => request.numberValue1,
            'dateValue1' => request.dateValue1,
            'dateTimeValue1' => request.dateTimeValue1,
            'booleanValue1' => request.booleanValue1,
            'maxRows' => effectiveMaxRows
        };
        validateBindNames(preparedQuery);

        ParsedRequest parsed = new ParsedRequest();
        parsed.originalIndex = requestIndex;
        parsed.preparedQuery = preparedQuery;
        parsed.objectApiName = canonicalObjectName;
        parsed.objectType = objectType;
        parsed.effectiveMaxRows = effectiveMaxRows;
        parsed.binds = binds;
        parsed.signature = JSON.serialize(
            new List<Object>{ preparedQuery, canonicalObjectName, binds }
        );
        return parsed;
    }

    private static QueryAnalysis analyzeQuery(String query) {
        if (containsOutsideString(query, ';')) {
            throw new SoqlConfigurationException(
                'Semikolons und mehrere Anweisungen sind nicht erlaubt.'
            );
        }
        if (containsOutsideString(query, '/*') ||
            containsOutsideString(query, '*/') ||
            containsOutsideString(query, '--') ||
            containsOutsideString(query, '//')) {
            throw new SoqlConfigurationException(
                'Kommentare sind in dieser Flow-Aktion nicht erlaubt.'
            );
        }

        List<TopLevelToken> tokens = tokenizeTopLevel(query);
        if (tokens.isEmpty() || tokens[0].value != 'SELECT') {
            throw new SoqlConfigurationException(
                'Nur SOQL-Abfragen erlaubt, die mit SELECT beginnen.'
            );
        }

        Integer fromIndex = indexOfToken(tokens, 'FROM', 1);
        if (fromIndex < 0 || fromIndex + 1 >= tokens.size()) {
            throw new SoqlConfigurationException(
                'Die SOQL-Abfrage enthält kein gültiges äußeres FROM.'
            );
        }

        String selectClause = query.substring(
            tokens[0].endIndex,
            tokens[fromIndex].startIndex
        );
        if (Pattern.compile(
            '(?i)\\b(COUNT|COUNT_DISTINCT|SUM|AVG|MIN|MAX)\\s*\\('
        ).matcher(selectClause).find()) {
            throw new SoqlConfigurationException(
                'Aggregatabfragen werden nicht unterstützt, weil das Ergebnis keine Record-Collection ist.'
            );
        }

        if (containsTokenSequence(tokens, 'GROUP', 'BY')) {
            throw new SoqlConfigurationException(
                'GROUP BY wird nicht unterstützt, weil AggregateResult nicht als Record-Collection gespeichert werden kann.'
            );
        }
        if (containsToken(tokens, 'FOR')) {
            throw new SoqlConfigurationException(
                'FOR UPDATE, FOR VIEW und FOR REFERENCE sind in einer reinen Getter-Aktion nicht erlaubt.'
            );
        }
        if (containsToken(tokens, 'UPDATE')) {
            throw new SoqlConfigurationException(
                'UPDATE TRACKING und UPDATE VIEWSTAT sind in einer reinen Getter-Aktion nicht erlaubt.'
            );
        }
        if (containsTokenSequence(tokens, 'ALL', 'ROWS')) {
            throw new SoqlConfigurationException('ALL ROWS ist nicht erlaubt.');
        }
        if (containsTokenSequence(tokens, 'WITH', 'SYSTEM_MODE') ||
            containsTokenSequence(tokens, 'WITH', 'USER_MODE')) {
            throw new SoqlConfigurationException(
                'WITH USER_MODE/SYSTEM_MODE nicht im SOQL angeben; die Action erzwingt USER_MODE.'
            );
        }

        QueryAnalysis analysis = new QueryAnalysis();
        analysis.rootObjectToken = tokens[fromIndex + 1].value;
        analysis.tokens = tokens;
        analysis.containsFieldsFunction = Pattern.compile(
            '(?i)\\bFIELDS\\s*\\('
        ).matcher(selectClause).find();

        Integer limitIndex = indexOfToken(tokens, 'LIMIT', fromIndex + 1);
        if (limitIndex >= 0) {
            analysis.limitToken = tokens[limitIndex];
            String afterLimit = query.substring(analysis.limitToken.endIndex).trim();
            Matcher limitMatcher = Pattern.compile(
                '(?i)^(\\d+|:maxRows)(?:\\s|$)'
            ).matcher(afterLimit);
            if (!limitMatcher.find()) {
                throw new SoqlConfigurationException(
                    'LIMIT muss eine feste Zahl oder :maxRows verwenden.'
                );
            }
            String configuredLimit = limitMatcher.group(1);
            if (!configuredLimit.equalsIgnoreCase(':maxRows')) {
                try {
                    analysis.explicitNumericLimit = Integer.valueOf(configuredLimit);
                } catch (Exception ex) {
                    throw new SoqlConfigurationException('LIMIT ist ungültig.');
                }
                if (analysis.explicitNumericLimit < 1) {
                    throw new SoqlConfigurationException(
                        'LIMIT muss mindestens 1 betragen.'
                    );
                }
            }
        }
        Integer offsetIndex = indexOfToken(tokens, 'OFFSET', fromIndex + 1);
        if (offsetIndex >= 0) {
            analysis.offsetToken = tokens[offsetIndex];
        }
        return analysis;
    }

    private static String applyRowLimit(
        String query,
        QueryAnalysis analysis
    ) {
        if (analysis.limitToken == null) {
            String limitClause = ' LIMIT :maxRows ';
            if (analysis.offsetToken == null) {
                return query + ' LIMIT :maxRows';
            }
            return query.substring(0, analysis.offsetToken.startIndex) +
                limitClause +
                query.substring(analysis.offsetToken.startIndex);
        }
        return query;
    }

    private static Boolean containsOutsideString(String source, String needle) {
        Boolean insideString = false;
        for (Integer i = 0; i < source.length(); i++) {
            String current = source.substring(i, i + 1);
            if (insideString) {
                if (current == '\\' && i + 1 < source.length()) {
                    i++;
                } else if (current == '\'') {
                    insideString = false;
                }
                continue;
            }
            if (current == '\'') {
                insideString = true;
                continue;
            }
            if (i + needle.length() <= source.length() &&
                source.substring(i, i + needle.length()) == needle) {
                return true;
            }
        }
        return false;
    }

    private static void validateBindNames(String query) {
        Set<String> bindNames = extractBindNames(query);
        for (String bindName : bindNames) {
            if (!ALLOWED_BIND_NAMES.contains(bindName)) {
                throw new SoqlConfigurationException(
                    'Unbekannte Bind-Variable :' + bindName +
                    '. Erlaubt sind: ' + String.join(
                        new List<String>(ALLOWED_BIND_NAMES),
                        ', '
                    ) + '.'
                );
            }
        }
    }

    private static Set<String> extractBindNames(String query) {
        Set<String> bindNames = new Set<String>();
        Boolean insideString = false;

        for (Integer i = 0; i < query.length(); i++) {
            String current = query.substring(i, i + 1);
            if (insideString) {
                if (current == '\\' && i + 1 < query.length()) {
                    i++;
                } else if (current == '\'') {
                    insideString = false;
                }
                continue;
            }
            if (current == '\'') {
                insideString = true;
                continue;
            }
            if (current != ':' || i + 1 >= query.length()) {
                continue;
            }

            String first = query.substring(i + 1, i + 2);
            if (!isIdentifierStart(first)) {
                continue;
            }
            Integer endIndex = i + 2;
            while (endIndex < query.length() &&
                isIdentifierPart(query.substring(endIndex, endIndex + 1))) {
                endIndex++;
            }
            bindNames.add(query.substring(i + 1, endIndex));
            i = endIndex - 1;
        }
        return bindNames;
    }

    private static List<TopLevelToken> tokenizeTopLevel(String query) {
        List<TopLevelToken> tokens = new List<TopLevelToken>();
        Boolean insideString = false;
        Integer parenthesisDepth = 0;

        for (Integer i = 0; i < query.length(); i++) {
            String current = query.substring(i, i + 1);
            if (insideString) {
                if (current == '\\' && i + 1 < query.length()) {
                    i++;
                } else if (current == '\'') {
                    insideString = false;
                }
                continue;
            }

            if (current == '\'') {
                insideString = true;
                continue;
            }
            if (current == '(') {
                parenthesisDepth++;
                continue;
            }
            if (current == ')') {
                parenthesisDepth--;
                if (parenthesisDepth < 0) {
                    throw new SoqlConfigurationException(
                        'Die SOQL-Abfrage enthält eine schließende Klammer ohne passende Öffnung.'
                    );
                }
                continue;
            }
            if (parenthesisDepth != 0 || !isIdentifierStart(current)) {
                continue;
            }

            Integer endIndex = i + 1;
            while (endIndex < query.length() &&
                isIdentifierPart(query.substring(endIndex, endIndex + 1))) {
                endIndex++;
            }
            tokens.add(new TopLevelToken(
                query.substring(i, endIndex).toUpperCase(),
                i,
                endIndex
            ));
            i = endIndex - 1;
        }

        if (insideString) {
            throw new SoqlConfigurationException(
                'Die SOQL-Abfrage enthält einen nicht abgeschlossenen Textwert.'
            );
        }
        if (parenthesisDepth != 0) {
            throw new SoqlConfigurationException(
                'Die SOQL-Abfrage enthält nicht korrekt geschlossene Klammern.'
            );
        }
        return tokens;
    }

    private static Boolean isIdentifierStart(String character) {
        return Pattern.matches('[A-Za-z_]', character);
    }

    private static Boolean isIdentifierPart(String character) {
        return Pattern.matches('[A-Za-z0-9_]', character);
    }

    private static Integer indexOfToken(
        List<TopLevelToken> tokens,
        String value,
        Integer startIndex
    ) {
        for (Integer i = startIndex; i < tokens.size(); i++) {
            if (tokens[i].value == value) {
                return i;
            }
        }
        return -1;
    }

    private static Boolean containsToken(
        List<TopLevelToken> tokens,
        String value
    ) {
        return indexOfToken(tokens, value, 0) >= 0;
    }

    private static Boolean containsTokenSequence(
        List<TopLevelToken> tokens,
        String first,
        String second
    ) {
        for (Integer i = 0; i + 1 < tokens.size(); i++) {
            if (tokens[i].value == first && tokens[i + 1].value == second) {
                return true;
            }
        }
        return false;
    }

    private static Map<String, String> buildObjectNameIndex() {
        Map<String, String> namesByLower = new Map<String, String>();
        for (String objectApiName : GLOBAL_DESCRIBE.keySet()) {
            namesByLower.put(objectApiName.toLowerCase(), objectApiName);
        }
        return namesByLower;
    }
}