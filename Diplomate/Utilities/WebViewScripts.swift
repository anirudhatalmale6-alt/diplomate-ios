import Foundation

enum WebViewScripts {

    /// Hides the Base44 "Edit with Base44" banner and any promotional elements
    static let hideBase44Branding: String = """
    (function() {
        'use strict';

        function hideBase44Elements() {
            // Hide "Edit with Base44" banner
            var selectors = [
                '[class*="base44"]',
                '[class*="Base44"]',
                '[id*="base44"]',
                '[id*="Base44"]',
                'a[href*="base44.app/edit"]',
                'a[href*="base44.app/create"]',
                '[class*="edit-banner"]',
                '[class*="editBanner"]',
                '[class*="powered-by"]',
                '[class*="poweredBy"]'
            ];

            selectors.forEach(function(selector) {
                try {
                    document.querySelectorAll(selector).forEach(function(el) {
                        var text = (el.textContent || '').toLowerCase();
                        if (text.includes('base44') || text.includes('edit with') || text.includes('powered by') || text.includes('built with')) {
                            el.style.display = 'none';
                            el.style.visibility = 'hidden';
                            el.style.height = '0';
                            el.style.overflow = 'hidden';
                            el.style.position = 'absolute';
                            el.style.pointerEvents = 'none';
                        }
                    });
                } catch(e) {}
            });

            // Also try to find any fixed/sticky banners at the bottom
            var allElements = document.querySelectorAll('div, a, span, p, section, footer');
            allElements.forEach(function(el) {
                var style = window.getComputedStyle(el);
                var text = (el.textContent || '').toLowerCase();
                if ((style.position === 'fixed' || style.position === 'sticky') &&
                    (text.includes('base44') || text.includes('edit with') || text.includes('built with'))) {
                    el.style.display = 'none';
                    el.style.visibility = 'hidden';
                }
            });
        }

        // Inject CSS to hide known Base44 elements
        var style = document.createElement('style');
        style.textContent = `
            [class*="base44-banner"],
            [class*="base44-footer"],
            [class*="edit-banner"],
            [class*="powered-by-base44"],
            a[href*="base44.app/edit"],
            a[href*="base44.app/create"] {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                overflow: hidden !important;
                pointer-events: none !important;
            }
        `;
        document.head.appendChild(style);

        // Run immediately
        hideBase44Elements();

        // Run again after a delay for dynamically loaded elements
        setTimeout(hideBase44Elements, 1000);
        setTimeout(hideBase44Elements, 3000);
        setTimeout(hideBase44Elements, 5000);

        // Observe DOM changes
        var observer = new MutationObserver(function(mutations) {
            hideBase44Elements();
        });
        observer.observe(document.body || document.documentElement, {
            childList: true,
            subtree: true
        });
    })();
    """

    /// Adapts viewport for native app feel
    static let viewportAdapter: String = """
    (function() {
        'use strict';

        // Ensure proper viewport
        var viewport = document.querySelector('meta[name="viewport"]');
        if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            document.head.appendChild(viewport);
        }
        viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';

        // Disable long-press context menu on images
        var style = document.createElement('style');
        style.textContent = `
            * {
                -webkit-touch-callout: none;
            }
            body {
                -webkit-user-select: auto;
                overscroll-behavior: none;
            }
            /* Safe area padding */
            body {
                padding-bottom: env(safe-area-inset-bottom) !important;
            }
        `;
        document.head.appendChild(style);
    })();
    """

    /// Intercepts external links and sends them to native handler
    static let externalLinkHandler: String = """
    (function() {
        'use strict';

        document.addEventListener('click', function(e) {
            var target = e.target;
            while (target && target.tagName !== 'A') {
                target = target.parentElement;
            }
            if (target && target.href) {
                var url = target.href;
                // If link goes outside base44.app, open in Safari
                if (url.indexOf('base44.app') === -1 &&
                    url.indexOf('javascript:') === -1 &&
                    url.indexOf('about:') === -1 &&
                    url.indexOf('#') !== 0) {
                    e.preventDefault();
                    e.stopPropagation();
                    window.webkit.messageHandlers.openExternal.postMessage(url);
                }
            }
        }, true);
    })();
    """
}
