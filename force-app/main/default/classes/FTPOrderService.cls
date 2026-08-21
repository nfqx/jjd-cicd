public with sharing class FTPOrderService {

    /*
     * Base FTP path
     */
    private static final String BASE_PATH = '/orders';
    

    /**
     * Loads CSV file content from FTP.
     */
    public static String loadOrderFile(String customerReferenceId, String fileName) {

        String filePath =buildFilePath(customerReferenceId, fileName);            
        return FTPClient.downloadFileAsString(filePath);
    }

    /**
     * Helper to build full FTP path.
     */
    private static String buildFilePath(String customerReferenceId, String fileName) {
        return BASE_PATH + '/' + customerReferenceId + '/' + fileName;
    }
}