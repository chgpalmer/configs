;;; Package --- Summary
;;; Commentary:
; need the above for some reason

;; For environment specific specific config
;; (E.g laptop, desktop, work, etc.)
(defvar config_env (getenv "_CONFIG_ENV_TYPE"))

;; eval/refresh/reload init.el. this loads the saved file, evaluates, and closes the file.
;; doesn't mess with init.el even if you already have it modified in a buffer
(global-set-key (kbd "M-g M-y") '(lambda () (interactive) (load-file user-init-file)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq large-file-warning-threshold nil)

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
 '(fill-column 80)
 '(org-startup-truncated nil)
 '(package-selected-packages
   (quote
    (magit meson-mode diff-hl yaml-mode protobuf-mode sublimity smooth-scroll smooth-scrolling hide-lines golden-ratio-scroll-screen column-marker popwin undo-tree helm-projectile helm flycheck iedit auto-complete-c-headers yasnippet auto-complete)))
 '(projectile-globally-ignored-directories
   (quote
    (".idea" ".ensime_cache" ".eunit" ".git" ".hg" ".fslckout" "_FOSSIL_" ".bzr" "_darcs" ".tox" ".svn" ".stack-work" "build"))))

;; have diff highlighting on by default 
;; hl-mode shows commit->saved diff,
;; flydiff also includes unsaved edits
;; amend (naming from git) shows hg qdif rather than hg dif
;; https://emacs.stackexchange.com/questions/5914/is-there-an-emacs-mode-which-highlights-differences-from-the-committed-version
;; https://github.com/dgutov/diff-hl/issues/11
(define-key global-map (kbd "M-g M-h") 'diff-hl-mode)
(define-key global-map (kbd "M-g M-;") 'diff-hl-previous-hunk)
(define-key global-map (kbd "M-g M-'") 'diff-hl-next-hunk)
(diff-hl-flydiff-mode)
(diff-hl-amend-mode)

;; terminal colors ish
;; if things randomly screw up and don't go back, you can set things with M-x customize-face
(set-background-color "black")
(set-foreground-color "wheat")
(set-cursor-color "#ffffff")
;; set for all new frames too
(setq default-frame-alist
      (append default-frame-alist
       '((foreground-color . "wheat")
 (background-color . "black")
 )))

;; font
(if config_env
  (when (string-match "laptop" config_env)
   ;;HiDPi laptop with DjaVu Sans Mono installed... have pretty fonts
    (set-face-attribute 'default nil :height 105) ;; increments of 5? lame... 105,6,7,8 are the same
    (custom-set-faces
     ;; custom-set-faces was added by Custom.
     ;; If you edit it by hand, you could mess it up, so be careful.
     ;; Your init file should contain only one such instance.
     ;; If there is more than one, they won't work right.
     '(default ((t (:inherit nil :stipple nil :background "black" :foreground "wheat" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 113 :width normal :foundry "PfEd" :family "DejaVu Sans Mono"))))
     '(cursor ((t (:background "#ffffff")))))
  )
)
;; hide toolbar
;(menu-bar-showhide-tool-bar-menu-customize-disable)
(tool-bar-mode 0)
;; hide menu bar
(menu-bar-mode 0)

;; show trailing whitespace
(setq-default show-trailing-whitespace t)

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
;; this makes text files wrap at line 80
;;(add-hook 'text-mode-hook 'auto-fill-mode)
(setq-default fill-column 80)

(global-set-key (kbd "<S-prior>") (lambda () (interactive) (move-to-window-line-top-bottom 1) (previous-line) (previous-line) ))
(global-set-key (kbd "<S-home>") (lambda () (interactive) (move-to-window-line nil) ))
(global-set-key (kbd "<S-next>") (lambda () (interactive) (move-to-window-line-top-bottom -1) (next-line) ))

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
(setq projectile-enable-caching t) ;; make helm projectile fast... maybe
;; undo in a sane way
(require 'undo-tree)
(global-undo-tree-mode)

;; popup windows happen at bottom please
;(require 'popwin)
;(push '("\*anything*" :regexp t :height 20) popwin:special-display-config)

;; swap between header and source... only in same dir unfortunately, making this mostly useless
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

;; do I even like any of the scrolling mods? I thought I would...
;; half page scrolling
;(require 'golden-ratio-scroll-screen)
;(global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
;(global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)
;(setq scroll-conservatively 1000)
;; smooth scrolling
;(require 'sublimity)
;(require 'sublimity-scroll)
;(require 'sublimity-map) ;; experimental
;(require 'sublimity-attractive)
;(sublimity-mode 1)
;(setq sublimity-scroll-weight 20
;      sublimity-scroll-drift-length 5)

;; sometimes this causes laggyness in emacs, which I found after lots of redious minor mode switching on and off 
;; tabbar-ruler, I'm only using the tabbar bit of this extension so not necessary really
;  (setq tabbar-ruler-global-tabbar t) ; If you want tabbar
;  (setq tabbar-ruler-global-ruler t) ; if you want a global ruler
;  (setq tabbar-ruler-popup-menu t) ; If you want a popup menu.
;  (setq tabbar-ruler-popup-toolbar t) ; If you want a popup toolbar
;  (setq tabbar-ruler-popup-scrollbar t) ; If you want to only show the
                                        ; scroll bar when your mouse is moving.
; ICONS ARE FUCKED IN EMACS 27 >:(
;  (require 'tabbar-ruler)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; C/C++ IDE stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; hide compilation window if successful (after 2 seconds)
(setq compilation-finish-function
  (lambda (buf str)
    (if (null (string-match ".*exited abnormally.*" str))
        ;;no errors, make the compilation window go away in a few seconds
        (progn
          (run-at-time
           "2 sec" nil 'delete-windows-on
           (get-buffer-create "*compilation*"))
          (message "No Compilation Errors!")))))
;; compile hotkey
(global-set-key (kbd "<f5>") 'recompile)

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
;(add-hook 'c++-mode-hook 'my:ac-c-header-init)
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

(defun list-subdirs (root)
  "Return a list of all (full qualified) subdirectories under parent directory ROOT."
  (split-string
   (shell-command-to-string
    (format "/home/$USER/scripts/subdir_list %s" root)
    )
   " ")
  )

(require 'projectile)
(defun setup-flycheck-gcc-includes ()
  "Set gcc includes for flycheck using projectile."
  (let ((root (ignore-errors (projectile-project-root))))
    (when root
      (setq-local flycheck-gcc-include-path
                  (list-subdirs root)))))

;; OLD function, doesn't require external command.
;; (add-hook 'c-mode-hook 'setup-flycheck-gcc-project-path)
;(require 'projectile)
;(defun setup-flycheck-gcc-includes ()
;  "Set gcc includes for flycheck using projectile."
;  (let ((root (ignore-errors (projectile-project-root))))
;    (when root
;      (setq-local flycheck-gcc-include-path
;                  (mapcar (lambda (dir-x)
;                            (concat root dir-x)) (projectile-current-project-dirs)))))))
;; Note: this only adds directories that projectile knows about. Projectile only knows
;; about dirs that contain tracked files. Directories containing only directories are missed,
;; causing issues in chip test (/src/include/ is missed...)

(add-hook 'c-mode-common-hook 'setup-flycheck-gcc-includes)
;; Solution: custom function that returns all directories, without exception
;; just need the syntax... something like:
;; (shell-command-to-string "find . -type d -name '.hg' -prune -o -type d -name 'build' -prune -o -print | sed 's/\(.*\)\/.*/\1/g' | sort -u")
(setq my_shell_output 0)
(setq my_shell_output
      (substring
      (shell-command-to-string (format "echo %s" "test"))
      )
      )


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

;;(global-set-key [prior] 'scroll-down-bit)
;;(global-set-key [next] 'scroll-up-bit)

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

;; kill line (dd) ctrl instead of awkward c-s-bspace
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
  "Function to cycle through styles."
  (interactive)
  (if (eq style-count style-count-max)
      (setq style-count 0)
    (setq style-count (+ style-count 1)))
  (style-select style-count))

(defun style-select (num)
  "Function to select tab and width settings based off NUM."
  "0 => Indent 2 style"
  "1 => Kernel style"
  (interactive)
  (if (eq num 0)
      (progn
        (message "indent-2 code style")
        (setq c-default-style "linux") 
        (c-set-offset 'substatement-open 0) ; indented braces are evil
        (c-set-offset 'case-label '+) ; normal case statement indenting!
        (setq c-basic-offset 2)
        (setq c-indent-level 2)
        (setq tab-width 2)
        (setq indent-tabs-mode nil)
        (column-marker-1 79)))
  (if (eq num 1)
      (progn
        (message "kernel code style")
        (setq c-default-style "linux")
        (c-set-offset 'substatement-open 0)
        (c-set-offset 'case-label '+) 
        (setq c-basic-offset 8)
        (setq c-indent-level 8)
        (setq tab-width 8)
        (setq indent-tabs-mode t)
        (column-marker-1 80))))

;; use indent=2 style indenting as default
(add-hook 'c-mode-common-hook (lambda () (interactive) (style-select 0)))

;; bind to something weird to keep emacs tradition
(global-set-key (kbd "C-x C-\\") 'style-cycle)

;; please no gnu style curly braces
;(setq c-default-style "linux")
;;(c-set-offset 'substatement-open 0)

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

;; (defun coding-style-ind2 () "ind-2 Coding Standard" (interactive) ()
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
;; Hiding and showing things!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; hiding pesky WITH_MC_MULTICORE blocks
(defun hide-matching-ifdef-blocks ()
  "Hide matching ifdefs."
  (interactive)
  (save-excursion
    ;; skip whitespace
    (back-to-indentation)
    ;; copy ifdef
    (set-mark-command nil)
    (search-forward-regexp "[^\s]+")
    (setq ifdef (buffer-substring (region-beginning) (region-end)))
    ;; skip whitespace
    (search-forward-regexp "[\s]+")
    ;; copy keyword
    (set-mark-command nil)
    (search-forward-regexp "[^\s\n]+")
    (setq keyword (buffer-substring (region-beginning) (region-end)))
    (setq searchterm (concat ifdef "[^\\s]+" keyword))
    ;; hide all instances
    (beginning-of-buffer)
    (while (search-forward-regexp searchterm nil t nil)
      (hide-ifdef-block 1 (point) (point)) ; first argument: nil=>"#ifdef keyword...", 1=>"..."
      )
    ;; for some reason the initial one is missed, so go back up to hide it
    (while (search-backward-regexp searchterm nil t nil)
      (hide-ifdef-block 1 (point) (point))
      )
    (message (concat "Hiding: " searchterm))
    )
  )
;; enable hiding modes in c
(add-hook 'c-mode-common-hook 'hide-ifdef-mode)
(global-set-key (kbd "C-@") 'hide-matching-ifdef-blocks)
(global-set-key (kbd "C-~") 'show-ifdefs)
(add-hook 'c-mode-common-hook 'outline-minor-mode)
(global-set-key (kbd "C-'") 'outline-hide-other)
(global-set-key (kbd "C-#") 'outline-show-all)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ??? stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ido
;(require 'ido)
;(ido-mode t)

;; pop tag, weirdly not bound by default
(global-set-key (kbd "M-*") 'pop-tag-mark)

;; zip through function definitons with C-TAB and S-TAB
;; (kinda like <C-M-a> and <C-M-e>, but less horrible)
(defun next-defun ()
  "Start of next defun."
  (interactive)
  (end-of-defun)
  (end-of-defun)
  (beginning-of-defun)
  )
(global-set-key (kbd "<C-tab>") 'next-defun)
(global-set-key (kbd "<backtab>") 'beginning-of-defun)
;(global-set-key (kbd "<C-iso-lefttab>") 'beginning-of-defun) ;; this keeps highlighting text! grr

;; bind M-Left, M-Right to window left/right
(global-set-key (kbd "C-,") 'prev-window)
(global-set-key (kbd "C-.") 'other-window)
(global-set-key (kbd "<M-left>") 'prev-window)
(global-set-key (kbd "<M-right>") 'other-window)

;; highlight whitespace at the end of lines red
(setq-default show-trailing-whitespace t)

(defun prev-window ()
  (interactive)
  (other-window -1))

;; make (C-l) recenter-top-bottom use more sensible order, top-middle-bottom!
(setq recenter-positions '(top middle bottom))

;; change all prompts to y or n
(fset 'yes-or-no-p 'y-or-n-p)

;; show matching parenthesis
(show-paren-mode 1)

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


;; make regexp searching the easy binding and vanilla searching the annoying binding
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)
(global-set-key (kbd "C-M-s") 'isearch-forward)
(global-set-key (kbd "C-M-r") 'isearch-backward)

;; "for smooth scrolling and disabling the automatic recentering of emacs when moving the cursor"
;; for me, this is just to stop emacs recentering the cursor when you move just outside the screen.
(setq scroll-conservatively most-positive-fixnum)
(setq scroll-margin 0 ;; why does this only work on buffer eval and not on startup?
scroll-conservatively 0
scroll-up-aggressively 0.01
scroll-down-aggressively 0.01)
(setq scroll-step            1
      scroll-conservatively  10000)

;; add line numbers to left
(global-linum-mode t)

;; C-z runs suspend frame, which is annoying when you accidentally hit it when
;; trying to save. unbind because I never use it
(global-unset-key (kbd "C-z"))

;; Never let the emacs 'saved' version of a file and the stored version deviate
;; e.g when doing an hg up, this forces reloading of the file
(global-auto-revert-mode)

;; fin
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; openR
(setq inferior-ess-r-program "/opt/microsoft/ropen/3.5.3/lib64/R/bin/R")

;; don't use tabs in artist mode (C-c ' will use this),
;; otherwise when you come back out of it tabs go to crap and you need to untabify
(add-hook 'artist-mode-hook (lambda () (setq indent-tabs-mode nil)))
