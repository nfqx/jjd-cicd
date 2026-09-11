public class CaseEmailPDFController {
    private Id caseId;
    public String pdfBase64 { get; set; }
    public String fileName { get; set; }
    public Boolean hasPDF { get; set; }

    // Extension Constructor linking to the Standard Case Controller
    public CaseEmailPDFController(ApexPages.StandardController stdController) {
        this.caseId = stdController.getId();
        this.hasPDF = false;
        loadLatestEmailPDF();
    }

    private void loadLatestEmailPDF() {
        // 1. Find the latest incoming Email Message associated with this Case
        List<EmailMessage> emails = [
            SELECT Id FROM EmailMessage 
            WHERE ParentId = :caseId AND Incoming = true AND HasAttachment = true 
            ORDER BY MessageDate DESC LIMIT 1
        ];

        if (emails.isEmpty()) return;
        Id emailId = emails[0].Id;

        // 2. Check Salesforce Files (ContentDocumentLink) first
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId FROM ContentDocumentLink 
            WHERE LinkedEntityId = :emailId
        ];

        if (!docLinks.isEmpty()) {
            Set<Id> docIds = new Set<Id>();
            for(ContentDocumentLink link : docLinks) {
                docIds.add(link.ContentDocumentId);
            }

            // Find the first PDF version data file
            List<ContentVersion> cvList = [
                SELECT VersionData, Title, FileExtension FROM ContentVersion 
                WHERE ContentDocumentId IN :docIds AND FileExtension = 'pdf' AND IsLatest = true 
                LIMIT 1
            ];

            if (!cvList.isEmpty()) {
                this.pdfBase64 = EncodingUtil.base64Encode(cvList[0].VersionData);
                this.fileName = cvList[0].Title + '.pdf';
                this.hasPDF = true;
                return; // File found, stop processing
            }
        }

        // 3. Fallback: Check Legacy Attachments table if Files framework isn't tracking it
        List<Attachment> legacyAtts = [
            SELECT Body, Name FROM Attachment 
            WHERE ParentId = :emailId AND ContentType = 'application/pdf' 
            LIMIT 1
        ];

        if (!legacyAtts.isEmpty()) {
            this.pdfBase64 = EncodingUtil.base64Encode(legacyAtts[0].Body);
            this.fileName = legacyAtts[0].Name;
            this.hasPDF = true;
        }
    }
}