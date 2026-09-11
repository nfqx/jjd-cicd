public class ContentDocumentLinkHandler {

    public static void handleAfterInsert(List<ContentDocumentLink> newLinks) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> contentDocIds = new Set<Id>();

        for (ContentDocumentLink cdl : newLinks) {
            // LinkedEntityId is the Case only when the file is attached directly to the Case
            if (String.valueOf(cdl.LinkedEntityId.getSObjectType()) == 'Case') {
                caseIds.add(cdl.LinkedEntityId);
                contentDocIds.add(cdl.ContentDocumentId);
            }
        }

        if (caseIds.isEmpty()) return;

        // Get file extensions for the newly linked documents
        Map<Id, ContentVersion> latestVersions = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, FileExtension
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            AND IsLatest = true
        ]) {
            latestVersions.put(cv.ContentDocumentId, cv);
        }

        // Map file extensions back to their Case
        Map<Id, Set<String>> caseIdToExtensions = new Map<Id, Set<String>>();
        for (ContentDocumentLink cdl : newLinks) {
            if (!caseIds.contains(cdl.LinkedEntityId)) continue;
            ContentVersion cv = latestVersions.get(cdl.ContentDocumentId);
            if (cv == null) continue;

            if (!caseIdToExtensions.containsKey(cdl.LinkedEntityId)) {
                caseIdToExtensions.put(cdl.LinkedEntityId, new Set<String>());
            }
            caseIdToExtensions.get(cdl.LinkedEntityId).add(cv.FileExtension?.toLowerCase());
        }

        List<Case> casesToUpdate = new List<Case>();
        for (Id caseId : caseIdToExtensions.keySet()) {
            Set<String> exts = caseIdToExtensions.get(caseId);
            Case c = new Case(Id = caseId);
            Boolean needsUpdate = false;

            if (exts.contains('mp3')) {
                c.isMP3__c = true;
                needsUpdate = true;
            }
            if (exts.contains('pdf')) {
                c.isPDF__c = true;
                needsUpdate = true;
            }
            if (needsUpdate) {
                casesToUpdate.add(c);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
}