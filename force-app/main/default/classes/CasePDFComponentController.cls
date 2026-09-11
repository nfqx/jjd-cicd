public class CasePDFComponentController {
    // Attribute assigned from the Component page
    public Id targetCaseId { 
        get; 
        set {
            targetCaseId = value;
            if(targetCaseId != null) {
                initPDFSearch();
            }
        } 
    }
    
    public String pdfBase64 { get; set; }
    public String fileName { get; set; }
    public Boolean hasPDF { get; set; }

    public CasePDFComponentController() {
        this.hasPDF = false;
    }

    private void initPDFSearch() {
        // 1. Search Files framework (ContentDocumentLink) directly on the Case
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink 
            WHERE LinkedEntityId = :targetCaseId
        ];
        
        if (!links.isEmpty()) {
            Set<Id> docIds = new Set<Id>();
            for(ContentDocumentLink l : links) { docIds.add(l.ContentDocumentId); }
            
            if(extractFile(docIds)) return; // PDF Found, exit method
        }

        // 2. Fallback: Search Files framework on Case Emails
        List<EmailMessage> emails = [
            SELECT Id FROM EmailMessage WHERE ParentId = :targetCaseId AND HasAttachment = true
        ];
        
        if (!emails.isEmpty()) {
            Set<Id> emailIds = new Set<Id>();
            for(EmailMessage em : emails) { emailIds.add(em.Id); }
            
            List<ContentDocumentLink> emailLinks = [
                SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :emailIds
            ];
            
            if(!emailLinks.isEmpty()) {
                Set<Id> docIds = new Set<Id>();
                for(ContentDocumentLink l : emailLinks) { docIds.add(l.ContentDocumentId); }
                
                if(extractFile(docIds)) return; // PDF Found, exit method
            }
        }
    }

    // Helper logic to grab and base64-encode the binary blob
    private Boolean extractFile(Set<Id> docIds) {
        List<ContentVersion> cvList = [
            SELECT VersionData, Title FROM ContentVersion 
            WHERE ContentDocumentId IN :docIds AND FileExtension = 'pdf' AND IsLatest = true 
            LIMIT 1
        ];
        
        if (!cvList.isEmpty()) {
            this.pdfBase64 = EncodingUtil.base64Encode(cvList[0].VersionData);
            this.fileName = cvList[0].Title + '.pdf';
            this.hasPDF = true;
            return true;
        }
        return false;
    }
}