import LightningTreeGrid from "lightning/treeGrid";
import chainRightsCell from "./chainRightsCell.html";
import linkwithcategory from "./linkwithcategory.html";

export default class CustomTreeGrid extends LightningTreeGrid {
  static customTypes = {
    chainRightsCell: {
      template: chainRightsCell,
      typeAttributes: ["type", "ownright", "inheritedright", "accountid", "owner"],
      standardCellLayout: true,
    },
    linkwithcategory: {
      template: linkwithcategory,
      typeAttributes: ["label", "href", "category", "target", "style"],
      standardCellLayout: true,
    },
  };
}