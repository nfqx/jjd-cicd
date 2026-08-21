import { LightningElement, api, track } from "lwc";
import first from '@salesforce/label/c.PaginationFirst';
import last from '@salesforce/label/c.PaginationLast';
import previous from '@salesforce/label/c.PaginationPrevious';
import next from '@salesforce/label/c.PaginationNext';
import number from '@salesforce/label/c.PaginationNumber';

const DELAY = 300;

export default class Pagination extends LightningElement {

    @api recordsCount;
    @api recordsPerPage;
    @api pageNumber;
    @api showNumberRecords = false;
    @track pageNo = 1;
    totalPages;
    startRecord;
    endRecord;
    end = false;
    pagelinks = [];
    numberOptions = [
        { value: 25, label: '25' },
        { value: 50, label: '50' },
        { value: 100, label: '100' },
        { value: 200, label: '200' },
    ];
    label = {
        first,
        last,
        next,
        previous,
        number
    }

    connectedCallback() {
        this.setPagination(true);
    }

    @api
    resetPage(pageNumber){
        this.pageNumber = pageNumber;
        this.setPagination(true);
    }
    @api
    resetPageAndRecordsPerPage(pageNumber, recordsPerPage){
        this.pageNumber = pageNumber;
        this.recordsPerPage = recordsPerPage;
        this.setPagination(true);
    }

    setPagination(resetPageNo) {
        //this.recordsCount = this.records.length;
        if(resetPageNo){
            this.pageNo = this.pageNumber;
            this.totalPages = Math.ceil(this.recordsCount / this.recordsPerPage);
            this.preparePaginationList(false);
        }
        this.pagelinks = [];
        for (let i = this.pageNo - 4; i <= this.pageNo + 4; i++) {
            if(i > 0 && i <= this.totalPages){
                this.pagelinks.push(i);
            }
        }
    }
    handleClick(event) {
        let label = event.target.label;
        if (label === this.label.first) {
            this.handleFirst();
        } else if (label === this.label.previous) {
            this.handlePrevious();
        } else if (label === this.label.next) {
            this.handleNext();
        } else if (label === this.label.last) {
            this.handleLast();
        }
    }

    handleNext() {
        this.pageNo += 1;
        this.preparePaginationList(true);
        this.setPagination(false);
    }

    handlePrevious() {
        this.pageNo -= 1;
        this.preparePaginationList(true);
        this.setPagination(false);
    }

    handleFirst() {
        this.pageNo = 1;
        this.preparePaginationList(true);
        this.setPagination(false);
    }

    handleLast() {
        this.pageNo = this.totalPages;
        this.preparePaginationList(true);
        this.setPagination(false);
    }

    handleChangeNumberRecords(numEvent) {
        this.recordsPerPage = parseInt(numEvent.target.value);
        const event = new CustomEvent('numberchange', {
            detail: { 
                numberperpage : this.recordsPerPage
            }
        });
        this.dispatchEvent(event);
    }

    preparePaginationList(sendEvent) {
        let begin = (this.pageNo - 1) * parseInt(this.recordsPerPage);
        let end = parseInt(begin) + parseInt(this.recordsPerPage);
        //this.recordsToDisplay = this.records.slice(begin, end);

        this.startRecord = begin + parseInt(1);
        this.endRecord = end > this.totalRecords ? this.totalRecords : end;
        this.end = end > this.totalRecords;
        if(sendEvent){
            const event = new CustomEvent('pagechange', {
                detail: { 
                    page : this.pageNo
                }
            });
            this.dispatchEvent(event);
        }

        window.clearTimeout(this.delayTimeout);
        let self = this;
        this.delayTimeout = setTimeout(() => {
            self.disableEnableActions();
        }, DELAY);
    }

    disableEnableActions() {
        let buttons = this.template.querySelectorAll("lightning-button");
        console.log()
        buttons.forEach(bun => {
            bun.disabled = false;
            if (bun.label === this.pageNo) {
                bun.disabled = true;
            } else if (bun.label === this.label.first) {
                bun.disabled = this.pageNo === 1;
            } else if (bun.label === this.label.previous) {
                bun.disabled = this.pageNo === 1;
            } else if (bun.label === this.label.next) {
                bun.disabled = this.pageNo === this.totalPages;
            } else if (bun.label === this.label.last) {
                bun.disabled = this.pageNo === this.totalPages;
            }
        });
    }

    handlePage(button) {
        this.pageNo = button.target.label;
        this.preparePaginationList(true);
        this.setPagination(false);
    }

}