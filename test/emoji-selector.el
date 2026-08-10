
(defvar ntfy--emoji-json-cache nil
  "Cache for the ntfy emoji JSON object.")

(defvar ntfy--emoji-json-url "https://raw.githubusercontent.com/binwiederhier/ntfy/refs/heads/main/scripts/emoji.json"
  "URL the ntfy emoji JSON list.")

(defvar ntfy--emoji-hashmap-cache nil
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



(defun ntfy--create-emoji-hashmap ()
  ""
  (setq ntfy--emoji-hashmap-cache (make-hash-table :test #'equal))
  (mapcar (lambda (elt)
            (puthash (plist-get elt :emoji)
                     (plist-get elt :aliases)
                     ntfy--emoji-hashmap-cache))
          (ntfy--get-emoji-json)))

(defun ntfy--interactive-emoji-selector ()
  "Interactively select multiple emojis and return them as a vector of
comma-separated tags."
  (interactive)
  ;; Create the hash if it not already created. This is cached.
  (unless ntfy--emoji-hashmap-cache
    (ntfy--create-emoji-hashmap))
  (let ((continue t)
        (emojis-selected nil))
    (while continue
      (push (elt (gethash (car (emoji--read-emoji))
                          ntfy--emoji-hashmap-cache)
                 0)
            emojis-selected)
      (setq continue (y-or-n-p "Add more Emojis?"))) ;; n -> nil quits loop
    (reverse emojis-selected)))




;; Currently, i am trying to combine the emoji function and my selection
;; function to select multiple emojis and have them converted
;;
;; It may just be simpler to call the get description function each time??
;;
;; Ahahahh how do i do it!!!
;; Run the profiler on the function after i have created it.
;;

;; Is there any need to keep the functionality of having the emoji alternate names as part of this? if i can make it work, sure but i could just strip it out and completing read from the

;; TESTING

;; Functions to use
;; emoji-insert
;; emoji-list
;; emoji-recent
;; emoji-search
;;
;; These all insert in buffer,

(progn
  (setq ntfy--emoji-json-cache nil
        ntfy--emoji-hashmap-cache nil)
  (ntfy--interactive-emoji-selector))
