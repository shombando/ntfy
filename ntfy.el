;;; ntfy.el --- publish notification using ntfy.sh -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Shom

;; Author: Shom Bandopadhaya <shom@bandopadhaya.com>
;; Created: 2022-04-30
;; Modified: 2022-04-30
;; Version: 0.1.1
;; Keywords: ntfy notification push-notification pub-sub
;; Package-Requires: ((emacs "27.2") (curl))
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:
;; Interface to use the https://ntfy.sh service (or self-hosted version) to send notification from Emacs.
;; 
;;; Code:

(defcustom ntfy-server nil
  "Set server for ntfy service."
  :group 'ntfy
  :type 'string)
  
(defcustom ntfy-topic nil
  "Set ntfy topic/channel."
  :group 'ntfy
  :type 'string)

(defcustom ntfy-header nil
  "Set header message for the notification."
  :group 'ntfy
  :type 'string)

(defcustom ntfy-tags nil
  "Set the emoji that'll appear before the header message.  Use comma separated string, see https://ntfy.sh/docs/publish/#tags-emojis for details."
  :group 'ntfy
  :type 'string)

(defvar ntfy--message nil
  "Message string that will be published.")

(defvar ntfy--link nil
  "URL that will be published.")

(defun ntfy-send-message (message)
  "Send ad-hoc MESSAGE from mini-buffer as notification."
  (interactive "sEnter message:")
  (setq ntfy--message message)
  (ntfy--publish-message))

(defun ntfy-send-message-with-header (header message)
  "Send ad-hoc MESSAGE from mini-buffer with custom HEADER as notification."
  (interactive "sEnter header: \nsEnter message: ")
  (setq ntfy-header header)
  (setq ntfy--message message)
  (ntfy--publish-message))

(defun ntfy-send-message-with-header-and-tags (tags header message)
  "Send ad-hoc MESSAGE from mini-buffer with custom HEADER and TAGS as notification."
  (interactive "sEnter tags (emoji codes, comma separated no spaces): \nsEnter header: \nsEnter message: ")
  (setq ntfy-tags tags)
  (setq ntfy-header header)
  (setq ntfy--message message)
  (ntfy--publish-message))

(defun ntfy--publish-message ()
"Publish message to server with curl."
(start-process "nfty.el" nil "curl"
		 "-H" (format "Title: %s" ntfy-header)
		 "-H" (format "Tags: %s" ntfy-tags)
		 "-d" (format "%s" ntfy--message)
		 (format "%s/%s" ntfy-server ntfy-topic)))

(defun ntfy-send-url (url)
  "Send URL from mini-buffer."
  (interactive "sEnter URL: \n")
  (setq ntfy--link url)
  (ntfy--publish-url))

(defun ntfy--publish-url ()
"Publish url to server with curl."
(start-process "nfty.el" nil "curl"
		 "-H" (format "Title: %s" "Emacs shared a URL")
		 "-H" (format "Tags: %s" "link")
		 "-H" (format "Actions: view, %s, %s" ntfy--link ntfy--link)
		 "-d" (format "%s" ntfy--link)
		 (format "%s/%s" ntfy-server ntfy-topic)))

(provide 'ntfy)
;;; ntfy.el ends here
