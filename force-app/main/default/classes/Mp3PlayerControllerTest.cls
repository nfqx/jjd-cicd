@isTest
private class Mp3PlayerControllerTest {

    @isTest
    static void testCaseWithFileAndRelatedEmailAttachment() {
        Case c = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Email');
        insert c;

        // Salesforce File (audio) attached directly to the case
        ContentVersion audioFile = new ContentVersion(
            Title = 'VoicemailClip',
            PathOnClient = 'VoicemailClip.mp3',
            VersionData = Blob.valueOf('fake audio bytes'),
            FirstPublishLocationId = c.Id
        );
        insert audioFile;

        // Salesforce File (non-audio) - should be excluded
        ContentVersion pdfFile = new ContentVersion(
            Title = 'CaseNotes',
            PathOnClient = 'CaseNotes.pdf',
            VersionData = Blob.valueOf('fake pdf bytes'),
            FirstPublishLocationId = c.Id
        );
        insert pdfFile;

        // Related inbound email with a legacy Attachment
        EmailMessage em = new EmailMessage(ParentId = c.Id, Subject = 'Inbound email', Incoming = true);
        insert em;

        Attachment audioAttachment = new Attachment(
            ParentId = em.Id,
            Name = 'call-recording.mp3',
            Body = Blob.valueOf('fake audio bytes'),
            ContentType = 'audio/mpeg'
        );
        insert audioAttachment;

        Attachment textAttachment = new Attachment(
            ParentId = em.Id,
            Name = 'transcript.txt',
            Body = Blob.valueOf('not audio'),
            ContentType = 'text/plain'
        );
        insert textAttachment;

        Test.startTest();
        List<Mp3PlayerController.AudioTrack> tracks = Mp3PlayerController.getAudioAttachments(c.Id);
        Test.stopTest();

        System.assertEquals(2, tracks.size(), 'Expected one audio File and one audio Attachment');

        Boolean foundFile = false;
        Boolean foundAttachment = false;
        for (Mp3PlayerController.AudioTrack t : tracks) {
            if (t.sourceLabel == 'File') {
                foundFile = true;
                System.assert(t.url.contains('/sfc/servlet.shepherd/version/download/'));
            }
            if (t.sourceLabel == 'Email Attachment') {
                foundAttachment = true;
                System.assert(t.url.contains('/servlet/servlet.FileDownload?file='));
            }
        }
        System.assert(foundFile, 'Should include the audio Salesforce File');
        System.assert(foundAttachment, 'Should include the audio legacy Attachment');
    }

    @isTest
    static void testNullRecordIdReturnsEmptyList() {
        Test.startTest();
        List<Mp3PlayerController.AudioTrack> tracks = Mp3PlayerController.getAudioAttachments(null);
        Test.stopTest();
        System.assertEquals(0, tracks.size());
    }

    @isTest
    static void testEmailMessageDirect() {
        Case c = new Case(Subject = 'Test Case 2', Status = 'New');
        insert c;
        EmailMessage em = new EmailMessage(ParentId = c.Id, Subject = 'Direct email test', Incoming = true);
        insert em;

        Attachment audioAttachment = new Attachment(
            ParentId = em.Id,
            Name = 'voicemail.wav',
            Body = Blob.valueOf('fake audio bytes'),
            ContentType = 'audio/wav'
        );
        insert audioAttachment;

        Test.startTest();
        List<Mp3PlayerController.AudioTrack> tracks = Mp3PlayerController.getAudioAttachments(em.Id);
        Test.stopTest();

        System.assertEquals(1, tracks.size());
        System.assertEquals('Email Attachment', tracks[0].sourceLabel);
    }
}