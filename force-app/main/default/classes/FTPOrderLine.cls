public class FTPOrderLine {

    public String childAccountNumber;
    public String productSku;
    public Decimal quantity;

    public FTPOrderLine() {
    }

    public FTPOrderLine(String childAccountNumber, String productSku, Decimal quantity) {
        this.childAccountNumber = childAccountNumber;
        this.productSku = productSku;
        this.quantity = quantity;
    }
}