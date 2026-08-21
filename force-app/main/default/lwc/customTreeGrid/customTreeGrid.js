import LightningTreeGrid from "lightning/treeGrid";
import chainRightsCell from "./chainRightsCell.html";

export default class CustomTreeGrid extends LightningTreeGrid {
  static customTypes = {
    chainRightsCell: {
      template: chainRightsCell,
      typeAttributes: ["type", "right", "accountid"],
      standardCellLayout: true,
    },
  };
}