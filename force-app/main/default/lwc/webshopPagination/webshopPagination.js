import { LightningElement, api, track } from "lwc";
import first from '@salesforce/label/c.WebshopPaginationFirst';
import last from '@salesforce/label/c.WebshopPaginationLast';
import previous from '@salesforce/label/c.WebshopPaginationPrevious';
import next from '@salesforce/label/c.WebshopPaginationNext';
import number from '@salesforce/label/c.WebshopPaginationNumber';

// Bootstrap
import { loadStyle } from 'lightning/platformResourceLoader';
import BOOTSTRAP from '@salesforce/resourceUrl/Bootstrap';

// Style
import webshopStyle from '@salesforce/resourceUrl/webshopStyle';

const DELAY = 300;

export default class WebshopPagination extends LightningElement {
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
    };

    connectedCallback() {
        this.setPagination(true);
        loadStyle(this, BOOTSTRAP);
        loadStyle(this, webshopStyle);
    }

    @api
    resetPage(pageNumber) {
        this.pageNumber = pageNumber;
        this.setPagination(true);
    }

    @api
    resetPageAndRecordsPerPage(pageNumber, recordsPerPage) {
        this.pageNumber = pageNumber;
        this.recordsPerPage = recordsPerPage;
        this.setPagination(true);
    }

    setPagination(resetPageNo) {
        if (resetPageNo) {
            this.pageNo = this.pageNumber;
            this.totalPages = Math.ceil(this.recordsCount / this.recordsPerPage);
            this.preparePaginationList(false);
        }
        this.pagelinks = [];
        for (let i = this.pageNo - 4; i <= this.pageNo + 4; i++) {
            if (i > 0 && i <= this.totalPages) {
                this.pagelinks.push(i);
            }
        }
    }

    handleClick(event) {
        let label = event.target.getAttribute('data-label');
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
        this.recordsPerPage = parseInt(numEvent.target.value, 10);
        const event = new CustomEvent('numberchange', {
            detail: { numberperpage: this.recordsPerPage },
        });
        this.dispatchEvent(event);
    }

    preparePaginationList(sendEvent) {
        let begin = (this.pageNo - 1) * parseInt(this.recordsPerPage, 10);
        let end = parseInt(begin) + parseInt(this.recordsPerPage, 10);

        this.startRecord = begin + 1;
        this.endRecord = end > this.recordsCount ? this.recordsCount : end;
        this.end = end > this.recordsCount;

        if (sendEvent) {
            const event = new CustomEvent('pagechange', {
                detail: { page: this.pageNo },
            });
            this.dispatchEvent(event);
        }

        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.disableEnableActions();
        }, 300); // Example delay constant
    }

    disableEnableActions() {
        let buttons = this.template.querySelectorAll("button");
        buttons.forEach((btn) => {
            btn.disabled = false;
            const label = btn.getAttribute("data-label");
            if (label === this.pageNo.toString()) {
                btn.disabled = true;
            } else if (label === this.label.first) {
                btn.disabled = this.pageNo === 1;
            } else if (label === this.label.previous) {
                btn.disabled = this.pageNo === 1;
            } else if (label === this.label.next) {
                btn.disabled = this.pageNo === this.totalPages;
            } else if (label === this.label.last) {
                btn.disabled = this.pageNo === this.totalPages;
            }
        });
    }

    handlePage(event) {
        this.pageNo = parseInt(event.target.getAttribute("data-label"), 10);
        this.preparePaginationList(true);
        this.setPagination(false);
    }
}