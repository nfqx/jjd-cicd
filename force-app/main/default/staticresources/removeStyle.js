const STYLESHEET_NAME = "custommodalcss";
function removeStylesheet() {
    const cssLinks = document.querySelectorAll("link");
    if (cssLinks) {
        cssLinks.forEach((link) => {
            const href = link.href;
            if (href && href.includes(STYLESHEET_NAME)) {
                link.remove();
            }
        });
    }
}

removeStylesheet();