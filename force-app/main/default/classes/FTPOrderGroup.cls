public class FTPOrderGroup {

    public String headAccountNumber;
    public List<FTPOrderLine> lines = new List<FTPOrderLine>();

    public FTPOrderGroup() {
    }

    public FTPOrderGroup(String headAccountNumber, List<FTPOrderLine> lines) {
        this.headAccountNumber = headAccountNumber;
        this.lines = lines;
    }
}