public with sharing class CustomAddressWrapper {
    public Id       recordId         { get; set; }
    public String   objectType       { get; set; }
    public Boolean  isAddressChanged { get; set; }
    public String   addressType      { get; set; }
    public String   fullAddress      { get; set; }
    public String   street           { get; set; }
    public String   city             { get; set; }
    public String   state            { get; set; }
    public String   postalCode       { get; set; }
    public String   country          { get; set; }
    public String   ecn              { get; set; }
    public String   externalId       { get; set; }

    public CustomAddressWrapper()    {}
}