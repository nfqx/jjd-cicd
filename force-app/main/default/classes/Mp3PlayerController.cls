public with sharing class Mp3PlayerController {

    private static final Set<String> AUDIO_EXTENSIONS = new Set<String>{
        'mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac', 'wma'
    };

    public class AudioTrack {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String url;
        @AuraEnabled public String sourceLabel;

        public AudioTrack(Id id, String name, String url, String sourceLabel) {
            this.id = id;
            this.name = name;
            this.url = url;
            this.sourceLabel = sourceLabel;
        }
    }

    /**
     * Returns every audio file attached to the given record.
     * - If recordId is a Case, also includes audio attached to any EmailMessage
     *   related to that Case (covers Email-to-Case voicemail/audio attachments).
     * - If recordId is an EmailMessage (or any other object), only that record's
     *   own attachments are returned.
     * Looks in both Salesforce Files (ContentDocumentLink/ContentVersion) and
     * legacy Attachment records, since inbound email attachments often land as
     * the latter.
     */
    @AuraEnabled(cacheable=true)
    public static List<AudioTrack> getAudioAttachments(Id recordId) {
        List<AudioTrack> tracks = new List<AudioTrack>();
        if (recordId == null) {
            return tracks;
        }

        Set<Id> targetIds = new Set<Id>{ recordId };

        if (recordId.getSObjectType() == Case.SObjectType) {
            for (EmailMessage em : [
                SELECT Id
                FROM EmailMessage
                WHERE ParentId = :recordId
                WITH SECURITY_ENFORCED
            ]) {
                targetIds.add(em.Id);
            }
        }

        // Salesforce Files
        if (Schema.sObjectType.ContentDocumentLink.isAccessible()
                && Schema.sObjectType.ContentVersion.isAccessible()) {
            Set<Id> contentDocIds = new Set<Id>();
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :targetIds
                WITH SECURITY_ENFORCED
            ]) {
                contentDocIds.add(cdl.ContentDocumentId);
            }

            if (!contentDocIds.isEmpty()) {
                for (ContentVersion cv : [
                    SELECT Id, Title, FileExtension
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocIds AND IsLatest = true
                    WITH SECURITY_ENFORCED
                ]) {
                    if (cv.FileExtension != null
                            && AUDIO_EXTENSIONS.contains(cv.FileExtension.toLowerCase())) {
                        tracks.add(new AudioTrack(
                            cv.Id,
                            cv.Title + '.' + cv.FileExtension,
                            '/sfc/servlet.shepherd/version/download/' + cv.Id,
                            'File'
                        ));
                    }
                }
            }
        }

        // Legacy Attachments (typical for inbound Email-to-Case attachments)
        if (Schema.sObjectType.Attachment.isAccessible()) {
            for (Attachment att : [
                SELECT Id, Name, ContentType
                FROM Attachment
                WHERE ParentId IN :targetIds
                WITH SECURITY_ENFORCED
            ]) {
                if (isAudioAttachment(att)) {
                    tracks.add(new AudioTrack(
                        att.Id,
                        att.Name,
                        '/servlet/servlet.FileDownload?file=' + att.Id,
                        'Email Attachment'
                    ));
                }
            }
        }

        return tracks;
    }

    private static Boolean isAudioAttachment(Attachment att) {
        if (att.ContentType != null && att.ContentType.toLowerCase().startsWith('audio/')) {
            return true;
        }
        if (att.Name != null) {
            String lowerName = att.Name.toLowerCase();
            for (String ext : AUDIO_EXTENSIONS) {
                if (lowerName.endsWith('.' + ext)) {
                    return true;
                }
            }
        }
        return false;
    }
}