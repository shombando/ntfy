
(defvar ntfy--emoji-json-cache nil
  "Cache for the ntfy emoji JSON object.")

(defvar ntfy--emoji-json-url "https://raw.githubusercontent.com/binwiederhier/ntfy/refs/heads/main/scripts/emoji.json"
  "URL the ntfy emoji JSON list.")

(defvar ntfy--emoji-hash (make-hash-table :test #'equal)
  "")

(defun ntfy--get-emoji-json (&optional force-refresh)
  "Return the parsed ntfy emoji JSON structure, a vector of plists.

Pass FORCE-REFRESH as t to bypass the cache."
  (or (and (not force-refresh)
           ntfy--emoji-json-cache)
      (let ((url-buf (url-retrieve-synchronously ntfy--emoji-json-url)))
        (when url-buf
          (with-current-buffer url-buf
            (goto-char (point-min))
            (when (re-search-forward "\r?\n\r?\n" nil t)
              (setq ntfy--emoji-json-cache (json-parse-buffer
                                            :object-type 'plist))))
          (kill-buffer url-buf))))
  ntfy--emoji-json-cache)

(defun ntfy--get-emoji-description ()
  "from `emoji--read-emoji` function
This slightly modifies the function to return the name and not the emoji."
  (let* ((table
          (if (not emoji-alternate-names)
              ;; If we don't have alternate names, do the efficient version.
              emoji--all-bases
            ;; Compute all the (possibly non-unique) names.
            (let ((table nil))
              (maphash
               (lambda (name glyph)
                 (push (concat name "\t" glyph) table))
               emoji--all-bases)
              (dolist (elem emoji-alternate-names)
                (dolist (name (cdr elem))
                  (push (concat name "\t" (car elem)) table)))
              (sort table #'string<))))
         (name
          (completing-read
           "Insert emoji: "
           (lambda (string pred action)
	         (if (eq action 'metadata)
		         (list 'metadata
		               (cons
                        'affixation-function
                        ;; Add the glyphs to the start of the displayed
                        ;; strings when TAB-ing.
                        (lambda (strings)
                          (mapcar
                           (lambda (name)
                             (if emoji-alternate-names
                                 (list name "" "")
                               (list name
                                     (concat
                                      (or (gethash name emoji--all-bases) " ")
                                      "\t")
                                     "")))
                           strings))))
	           (complete-with-action action table string pred)))
           nil t)))
    (if (cl-plusp (length name))
        ;; MODIFIED: return name not emoji.
        name
      (user-error "You didn't specify an emoji"))))

(defun ntfy--create-emoji-hashmap ()
  ""
  (let ((json (ntfy--get-emoji-json)))
    (setq ntfy--emoji-hash (make-hash-table :test #'equal))
    (mapcar (lambda (elt)
              (puthash (plist-get elt :description)
                       (plist-get elt :aliases)
                       ntfy--emoji-hash))
            json)))

;; Testing
