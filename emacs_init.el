
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; start package.el with emacs
(require 'package)
;; add melpa to repository list
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))
;; init package.el
(package-initialize)

;; everyone else has this?
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (diff-hl golden-ratio-scroll-screen column-marker popwin undo-tree helm-projectile helm flycheck iedit auto-complete-c-headers yasnippet auto-complete))))

;; terminal colors ish
(set-background-color "black")
(set-foreground-color "wheat")
(add-to-list 'default-frame-alist '(foreground-color . "wheat"))
(add-to-list 'default-frame-alist '(background-color . "black"))

;; hide toolbar + menu bar
(menu-bar-showhide-tool-bar-menu-customize-disable)
(menu-bar-mode -1)

;; where packages live
(add-to-list 'load-path "~/.emacs.d/lisp")
(add-to-list 'load-path "~/.emacs.d/lisp/emacs-dashboard")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Packages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; trying to active the 80 column highlight
(require 'column-marker)
(add-hook 'c-mode-common-hook (lambda () (interactive) (column-marker-1 80)))
(global-set-key [?\C-c ?m] 'column-marker-1)
;2345678901234567890123456789012345678901234567890123456789012345678901234567890abcdef

;; helm, projectile, helm-projectile
(require 'helm-config)
(projectile-global-mode)
;; replace default find files keybind with helm find files
(define-key global-map (kbd "C-x C-f") 'helm-find-files)
(define-key global-map (kbd "C-c C-f") 'helm-recentf)
(define-key global-map (kbd "M-x") 'helm-M-x)
;; use tab for completion, helm tab is insane!
;(define-key helm-find-files-map "\t" 'helm-execute-persistent-action)
;; use helm instead of ido/default for viewing results
(require 'helm-projectile)
(helm-projectile-on)

;; undo in a sane way
(require 'undo-tree)
(global-undo-tree-mode)

;; popup windows happen at bottom please
;(require 'popwin)
;(push '("\*anything*" :regexp t :height 20) popwin:special-display-config)

;; swap between header and source... only in same dir unfortunately
(add-hook 'c-mode-common-hook
  (lambda() 
    (local-set-key  (kbd "C-c o") 'ff-find-other-file)))

(require 'dashboard)
(dashboard-setup-startup-hook)
(setq dashboard-items '((recents  . 5)
			(bookmarks . 5)
                        (projects . 5)
                        ;(agenda . 5)
			))

(require 'golden-ratio-scroll-screen)
(global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
(global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; C/C++ IDE stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; start auto-complete with emacs
(require 'auto-complete)
;; do default config for auto-complete
(require 'auto-complete-config)
(ac-config-default)
;; start yasnippet with emacs
(require 'yasnippet)
(yas-global-mode 1)
;; let's define a function which inits auto-complete-c-headers and gets called for c/c++ hooks
(defun my:ac-c-header-init ()
  (require 'auto-complete-c-headers)
  (add-to-list 'ac-sources 'ac-source-c-headers)
  (add-to-list 'achead:include-directories '"/usr/lib/gcc/x86_64-redhat-linux/6.3.1/include") ;gcc -xc -E -v -
)
;; now lets call this function from c/c++ hooks
(add-hook 'c++-mode-hook 'my:ac-c-header-init)
(add-hook 'c-mode-hook 'my:ac-c-header-init)
;; iedit keybinding
(define-key global-map (kbd "C-c ;") 'iedit-mode)

;; make flycheck use projectile project root for include paths
;; (defun setup-flycheck-gcc-project-path ()
;;   (let ((root (ignore-errors (projectile-project-root))))
;;     (when root
;;       (add-to-list 
;;        (make-variable-buffer-local 'flycheck-gcc-include-path)
;;        root)))

;; (add-hook 'c-mode-hook 'setup-flycheck-gcc-project-path)
(require 'projectile)
(defun setup-flycheck-gcc-includes ()
  "Set gcc includes for flycheck using projectile."
  (let ((root (ignore-errors (projectile-project-root))))
    (when root
      (setq-local flycheck-gcc-include-path
                  (mapcar (lambda (dir-x)
                            (concat root dir-x)) (projectile-current-project-dirs))))))

(add-hook 'c-mode-common-hook 'setup-flycheck-gcc-includes) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Syntax stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; syntax checking
(require 'flycheck)
(global-flycheck-mode)

;; turn on semantic
(semantic-mode 1)
;; semantic as suggestion to autocomplete
;; hook to c-mod-common-hook
(defun my:add-semantic-to-autocomplete()
  (add-to-list 'ac-sources 'ac-source-semantic)
)
(add-hook 'c-mode-common-hook 'my:add-semantic-to-autocomplete)

;; show prototype of thing under cursor at bottom in idle time
;(global-semantic-idle-summary-mode t)
;; I found this too annoying when you need the minibuffer for other things like save compile prompts

;; Make <TAB> in C mode just insert a tab if point is in the middle of a line.
(setq c-tab-always-indent nil)

;; Make pgup and pgdown just scroll by a little bit
(defun scroll-up-bit ()
  (interactive)
  (scroll-up 5))
   
(defun scroll-down-bit ()
  (interactive)                    
  (scroll-down 5))
   
(global-set-key [prior] 'scroll-down-bit)
(global-set-key [next] 'scroll-up-bit)

;; something more familar for multline comments!
(global-set-key (kbd "<C-return>") 'c-indent-new-comment-line)
(global-set-key (kbd "<C-RET>") 'c-indent-new-comment-line)
(global-set-key (kbd "<S-return>") 'c-indent-new-comment-line)
(global-set-key (kbd "<S-RET>") 'c-indent-new-comment-line)

;; winner mode... i.e undo and redo window configuration changes
(when (fboundp 'winner-mode)
  (winner-mode 1))


;; insert an empty line after the current line and position the cursor on its indented beginning
(defun smart-open-line ()
  "Insert an empty line after the current line.
Position the cursor at its beginning, according to the current mode."
  (interactive)
  (move-end-of-line nil)
  (newline-and-indent))
(defun smart-open-line-above ()
  "Insert an empty line above the current line.
Position the cursor at it's beginning, according to the current mode."
  (interactive)
  (move-beginning-of-line nil)
  (newline-and-indent)
  (forward-line -1)
  (indent-according-to-mode))

(global-set-key (kbd "M-o") 'smart-open-line)
(global-set-key (kbd "M-O") 'smart-open-line-above)

;; kill line (dd) ctrl-backspace instead of awkward c-s-bspace
(global-set-key (kbd "<S-backspace>") 'kill-whole-line)
;; copy line (yy) ctrl-backspace
(defun copy-whole-line ()
  (interactive)
  (kill-whole-line)
  (yank)
  (forward-line -1))
(global-set-key (kbd "<C-backspace>") 'copy-whole-line)

;; duplicate line
;; https://stackoverflow.com/questions/88399/how-do-i-duplicate-a-whole-line-in-emacs
(defun duplicate-line (arg)
  "Duplicate current line, leaving point in lower line."
  (interactive "*p")

  ;; save the point for undo
  (setq buffer-undo-list (cons (point) buffer-undo-list))

  ;; local variables for start and end of line
  (let ((bol (save-excursion (beginning-of-line) (point)))
        eol)
    (save-excursion

      ;; don't use forward-line for this, because you would have
      ;; to check whether you are at the end of the buffer
      (end-of-line)
      (setq eol (point))

      ;; store the line and disable the recording of undo information
      (let ((line (buffer-substring bol eol))
            (buffer-undo-list t)
            (count arg))
        ;; insert the line arg times
        (while (> count 0)
          (newline)         ;; because there is no newline in 'line'
          (insert line)
          (setq count (1- count)))
        )

      ;; create the undo information
      (setq buffer-undo-list (cons (cons eol (point)) buffer-undo-list)))
    ) ; end-of-let

  ;; put the point in the lowest line and return
  (next-line arg))

(global-unset-key (kbd "C-d"))
(global-set-key (kbd "C-d") 'duplicate-line)

;; stop accidentally doing 'keyboard-escape-quit because I'm clicking ctrl too fast
;; (which I bound to esc on short press with xcape...)
(global-unset-key (kbd "ESC ESC ESC"))

;; change horizontal split to vertical
(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
         (next-win-buffer (window-buffer (next-window)))
         (this-win-edges (window-edges (selected-window)))
         (next-win-edges (window-edges (next-window)))
         (this-win-2nd (not (and (<= (car this-win-edges)
                     (car next-win-edges))
                     (<= (cadr this-win-edges)
                     (cadr next-win-edges)))))
         (splitter
          (if (= (car this-win-edges)
             (car (window-edges (next-window))))
          'split-window-horizontally
        'split-window-vertically)))
    (delete-other-windows)
    (let ((first-win (selected-window)))
      (funcall splitter)
      (if this-win-2nd (other-window 1))
      (set-window-buffer (selected-window) this-win-buffer)
      (set-window-buffer (next-window) next-win-buffer)
      (select-window first-win)
      (if this-win-2nd (other-window 1))))))

(global-set-key (kbd "C-x |") 'toggle-window-split)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code style
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(setq tab-width 2) ; how many spaces a tab is
;(setq c-basic-offset 2) ; how much to indent after { ...
;(setq indent-tabs-mode nil) ; use spaces instead of tabs


(defvar style-count 0)
(defvar style-count-max 1)

(defun style-cycle ()
  "Function to cycle through things."
  (interactive)
  (if (eq style-count style-count-max)
      (setq style-count 0)
    (setq style-count (+ style-count 1)))
  (style-fn style-count))

;; please no gnu style curly braces
(setq c-default-style "linux")
;(c-set-offset 'substatement-open 0)

(defun style-fn (num)
  "Function to select tab settings based off NUM."
  (interactive)
  (if (eq num 0)
      (progn
	(message "indent=2 code style")
	(setq c-basic-offset 2)
	(setq c-indent-level 2)
	(setq tab-width 2)
	(setq indent-tabs-mode nil)
	(column-marker-1 79))) ;; 79 so you can include a wrap character, maybe...
  (if (eq num 1)
      (progn
	(message "indent=4 code style")
	(setq c-basic-offset 4)
	(setq c-indent-level 4)
	(setq tab-width 4)
	(setq indent-tabs-mode nil)
	(column-marker-1 100))))
  (if (eq num 2)
      (progn
	(message "kernel code style")
	(setq c-basic-offset 8)
	(setq c-indent-level 8)
	(setq tab-width 8)
	(setq indent-tabs-mode t)
	(column-marker-1 80))))

;; Note the following from the style guide
;; /*
;; ** Local variables:
;; ** c-basic-offset: 2
;; ** c-indent-level: 2
;; ** indent-tabs-mode: 0
;; ** fill-column: 75
;; ** tab-width: 8
;; ** End:
;; */
;; /*
;; * Local variables:
;; * c-basic-offset: 8
;; * c-indent-level: 8
;; * tab-width: 8
;; * indent-tabs-mode: 1
;; * fill-column: 75
;; * End:
;; */

(global-set-key (kbd "C-x C-\\") 'style-cycle)


;; default tab width = 2
;(setq-default indent-tabs-mode t)
;(setq-default tab-width 8) ; Assuming you want your tabs to be four spaces wide
;(defvaralias 'c-basic-offset 'tab-width)

;; create 79 column multi-line comment header (use M-j to extend, use M-; to turn highlighted lineinto comment (or non highlighted, end of line into comment))
;; (global-set-key (kbd "C-x C-\\") 'abcd)
;; (defun abcd ()
;;   (interactive)
;;   (insert (shell-command-to-string "echo '/****************************************************************************\n * \n ****************************************************************************/'"))
;;   (previous-line)
;;   (previous-line)
;;   (end-of-line))

;; (defun coding-style-2ind () "2ind Coding Standard" (interactive) ()
;;   (setq c-basic-offset 2
;; 	c-indent-level 2
;; 	tab-width 8
;; 	indent-tabs-mode 0
;; 	fill-column 75))

;; (defun coding-style-kernel () "Linux Kernel Coding Standard" (interactive) ()
;;   (setq c-basic-offset 8
;; 	c-indent-level 8
;; 	tab-width 8
;; 	indent-tabs-mode 1
;; 	fill-column 75))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ??? stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ido
;(require 'ido)
;(ido-mode t)

;; pop tag, weirdly not bound by default
(global-set-key (kbd "M-*") 'pop-tag-mark)

;; highlight whitespace at the end of lines red
(setq-default show-trailing-whitespace t)

;; next buffer, previous buffer with M-left/right
;; bind C-,/C-. to window left/right
(global-set-key (kbd "M-<left>") 'other-window)
(global-set-key (kbd "M-<right>") 'prev-window)
(defun prev-window ()
  (interactive)
  (other-window -1))

;; make (C-l) recenter-top-bottom use more sensible order, top-middle-bottom!
(setq recenter-positions '(top middle bottom))

;; change all prompts to y or n
(fset 'yes-or-no-p 'y-or-n-p)

;; show matching parenthesis
(show-paren-mode 1)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; grey out #if 0 -> #endif
;; http://stackoverflow.com/questions/4549015/in-c-c-mode-in-emacs-change-face-of-code-in-if-0-endif-block-to-comment-f?noredirect=1&lq=1
(defun my-c-mode-font-lock-if0 (limit)
  (save-restriction
    (widen)
    (save-excursion
      (goto-char (point-min))
      (let ((depth 0) str start start-depth)
        (while (re-search-forward "^\\s-*#\\s-*\\(if\\|else\\|endif\\)" limit 'move)
          (setq str (match-string 1))
          (if (string= str "if")
              (progn
                (setq depth (1+ depth))
                (when (and (null start) (looking-at "\\s-+0"))
                  (setq start (match-end 0)
                        start-depth depth)))
            (when (and start (= depth start-depth))
              (c-put-font-lock-face start (match-beginning 0) 'font-lock-comment-face)
              (setq start nil))
            (when (string= str "endif")
              (setq depth (1- depth)))))
        (when (and start (> depth 0))
          (c-put-font-lock-face start (point) 'font-lock-comment-face)))))
  nil)

(defun my-c-mode-common-hook ()
  (font-lock-add-keywords
   nil
   '((my-c-mode-font-lock-if0 (0 font-lock-comment-face prepend))) 'add-to-end))

(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

;; don't use tabs when making pretty things in artist mode
(add-hook 'artist-mode-hook (lambda () (setq indent-tabs-mode nil)))

;; use regex search instead of normal search
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)


;;; xterm key decoding
;; As of this writing, emacs does not correctly recognize some xterm
;; key sequences.  Add code to deal with these.
;(defun add-escape-key-mapping-alist (escape-prefix key-prefix
;                                                   suffix-alist)
;  "Add mappings for up, down, left and right keys for a given list
;of escape sequences and list of keys."
;  (while suffix-alist
;    (let ((escape-suffix (car (car suffix-alist)))
;          (key-suffix (cdr (car suffix-alist))))
;      (define-key input-decode-map (concat escape-prefix escape-suffix)
;        (read-kbd-macro (concat key-prefix key-suffix))))
;    (setq suffix-alist (cdr suffix-alist))))
;
;(defun my-setup-input-decode-map ()
;  (setq nav-key-pair-alist
;        '(("A" . "<up>") ("B" . "<down>") ("C" . "<right>") ("D" . "<left>")
;          ("H" . "<home>") ("F" . "<end>")))
;
;  (add-escape-key-mapping-alist "\e[1;2" "S-" nav-key-pair-alist)
;  (add-escape-key-mapping-alist "\e[1;3" "M-" nav-key-pair-alist)
;  (add-escape-key-mapping-alist "\e[1;4" "M-S-" nav-key-pair-alist)
;  (add-escape-key-mapping-alist "\e[1;6" "C-S-" nav-key-pair-alist)
;  (add-escape-key-mapping-alist "\e[1;7" "M-C-" nav-key-pair-alist)
;  (add-escape-key-mapping-alist "\e[1;8" "M-C-S-" nav-key-pair-alist))
;
;;; Package --- Summary
;;; Commentary:
; need the above for some reason
;; fin
