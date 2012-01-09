;; Copyright (c) 1991-2002, The Numerical ALgorithms Group Ltd.
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;     - Redistributions of source code must retain the above copyright
;;       notice, this list of conditions and the following disclaimer.
;;
;;     - Redistributions in binary form must reproduce the above copyright
;;       notice, this list of conditions and the following disclaimer in
;;       the documentation and/or other materials provided with the
;;       distribution.
;;
;;     - Neither the name of The Numerical ALgorithms Group Ltd. nor the
;;       names of its contributors may be used to endorse or promote products
;;       derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
;; IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
;; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;; PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
;; OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package "BOOT")

;; definition of our stream structure
(defstruct libstream  mode dirname (indextable nil)  (indexstream nil))
;indextable is a list of entries (key class <location or filename>)
;filename is of the form filenumber.lsp or filenumber.o

(defun |make_compiler_output_stream|(lib basename)
   (open (concat (libstream-dirname lib) "/" basename ".lsp")
         :direction :output :if-exists :supersede))

(defun |rMkIstream| (file)
  (let ((stream nil)
        (fullname (|make_input_filename| file)))
               (setq stream (|get_input_index_stream| fullname))
               (if (null stream)
                   (ERROR (format nil "Library ~s doesn't exist"
                              (|make_filename| file))))
               (make-libstream :mode 'input  :dirname fullname
                      :indextable (|get_index_table_from_stream| stream)
                               :indexstream stream)))

(defun |rMkOstream| (file)
    (let ((stream nil)
          (indextable nil)
          (fullname (|make_full_namestring| file)))
        (case (file-kind fullname)
            (-1 (makedir fullname))
            (0 (error (format nil "~s is an existing file, not a library"
                              fullname)))
            (1 nil)
            (otherwise (error "Bad value from directory?")))
        (multiple-value-setq (stream indextable)
            (|get_io_index_stream| fullname))
        (make-libstream :mode 'output  :dirname fullname
                        :indextable indextable
                        :indexstream stream )))

(defvar |$index_filename| "index.KAF")

;get the index table of the lisplib in dirname
(defun getindextable (dirname)
  (let ((index-file (concat dirname "/" |$index_filename|)))
     (if (probe-file index-file)
         (with-open-file (stream index-file)
             (|get_index_table_from_stream| stream))
            ;; create empty index file to mark directory as lisplib
         (with-open-file (stream index-file :direction :output) nil))))

;get the index stream of the lisplib in dirname
(defun |get_input_index_stream| (dirname)
  (let ((index-file (concat dirname "/" |$index_filename|)))
    (open index-file :direction :input :if-does-not-exist nil)))

(defun |get_index_table_from_stream| (stream)
  (let ((pos (read  stream)))
    (cond ((numberp pos)
           (file-position stream pos)
           (read stream))
          (t pos))))

(defun |get_io_index_stream| (dirname)
  (let* ((index-file (concat dirname "/" |$index_filename|))
         (stream (open index-file :direction :io :if-exists :overwrite
                       :if-does-not-exist :create))
         (indextable ())
         (pos (read stream nil nil)))
    (cond ((numberp pos)
           (file-position stream pos)
           (setq indextable (read stream))
           (file-position stream pos))
          (t (file-position stream 0)
             (princ "                    " stream)
             (setq indextable pos)))
    (values stream indextable)))

;substitute indextable in dirname

(defun |write_indextable| (indextable stream)
  (let ((pos (file-position stream)))
    (write indextable :stream stream :level nil :length nil :escape t)
    (finish-output stream)
    (file-position stream 0)
    (princ pos stream)
    (finish-output stream)))

(defun putindextable (indextable dirname)
  (with-open-file
    (stream (concat dirname "/" |$index_filename|)
             :direction :io :if-exists :overwrite
             :if-does-not-exist :create)
    (file-position stream :end)
    (|write_indextable| indextable stream)))

;; (RREAD key rstream)
(defun |rread0| (key rstream &optional (error-val nil error-val-p))
  (if (equal (libstream-mode rstream) 'output) (error "not input stream"))
  (let* ((entry
         (and (stringp key)
              (assoc key (libstream-indextable rstream) :test #'string=)))
         (file-or-pos (and entry (caddr entry))))
    (cond ((null entry)
           (if error-val-p error-val (error (format nil "key ~a not found" key))))
          ((null (caddr entry)) (cdddr entry))  ;; for small items
          ((numberp file-or-pos)
           (file-position (libstream-indexstream rstream) file-or-pos)
           (read (libstream-indexstream rstream)))
          (t
           (with-open-file
            (stream (concat (libstream-dirname rstream) "/" file-or-pos))
            (read  stream))) )))

;; (RKEYIDS filearg) -- interned version of keys
(defun RKEYIDS (&rest filearg)
  (mapcar #'intern (mapcar #'car (getindextable
                                  (|make_input_filename| filearg)))))

;; (RWRITE cvec item rstream)
(defun |rwrite0| (key item rstream)
  (if (equal (libstream-mode rstream) 'input) (error "not output stream"))
  (let ((stream (libstream-indexstream rstream))
        (pos (if item (cons (file-position (libstream-indexstream rstream)) nil)
               (cons nil item))))   ;; for small items
    (|make_entry| (string key) rstream pos)
    (when (numberp (car pos))
          (write item :stream stream :level nil :length nil
                 :circle t :array t :escape t)
          (terpri stream))))

(defun |make_entry| (key rstream value-or-pos)
   (let ((entry (assoc key (libstream-indextable rstream) :test #'equal)))
     (if (null entry)
         (push (setq entry (cons key (cons 0 value-or-pos)))
               (libstream-indextable rstream))
       (progn
         (if (stringp (caddr entry)) ($ERASE (caddr entry)))
         (setf (cddr entry) value-or-pos)))
     entry))


(defun rshut (rstream)
  (if (eq (libstream-mode rstream) 'output)
      (|write_indextable| (libstream-indextable rstream)
                          (libstream-indexstream rstream)))
  (close (libstream-indexstream rstream)))

;; filespec is id or list of 1, 2 or 3 ids
;; filearg is filespec or 1, 2 or 3 ids
;; (RPACKFILE filearg)  -- compiles code files and converts to compressed format
(defun rpackfile (filespec)
  (setq filespec (|make_filename| filespec))
  (if (string= (pathname-type filespec) "NRLIB")
    (let ((base (pathname-name filespec)))
         (|recompile_lib_file_if_necessary|
             (concatenate 'string (namestring filespec) "/" base ".lsp")))
    (error "RPACKFILE only works on .NRLIB-s"))
  filespec)

(defun |recompile_lib_file_if_necessary| (lfile)
   (let* ((bfile (make-pathname :type *lisp-bin-filetype* :defaults lfile))
          (bdate (and (probe-file bfile) (file-write-date bfile)))
          (ldate (and (probe-file lfile) (file-write-date lfile))))
     (if ldate
         (if (and bdate (> bdate ldate)) nil
           (progn (|compile_lib_file| lfile) (list bfile))))))

#+:GCL
(defun spad-fixed-arg (fname )
   (and (equal (symbol-package fname) (find-package "BOOT"))
        (not (get fname 'compiler::spad-var-arg))
        (search ";" (symbol-name fname))
        (or (get fname 'compiler::fixed-args)
            (setf (get fname 'compiler::fixed-args) t)))
   nil)

#+:GCL
(defun |compile_lib_file|(fn)
  (unwind-protect
      (progn
        (trace (compiler::fast-link-proclaimed-type-p
                :exitcond nil
                :entrycond (spad-fixed-arg (car system::arglist))))
        (trace (compiler::t1defun :exitcond nil
                :entrycond (spad-fixed-arg (caar system::arglist))))
        (apply #'compile-file fn))
    (untrace compiler::fast-link-proclaimed-type-p compiler::t1defun)))
#-:GCL
(defun |compile_lib_file|(fn)
  (if FRICAS-LISP::algebra-optimization
      (proclaim (cons 'optimize FRICAS-LISP::algebra-optimization)))
  (compile-file fn))


;; (RDROPITEMS filearg keys) don't delete, used in files.spad
(defun rdropitems (filearg keys &aux (ctable (getindextable filearg)))
  (mapc #'(lambda(x)
           (setq ctable (delete x ctable :key #'car :test #'equal)) )
           (mapcar #'string keys))
  (putindextable ctable filearg))

;; cms file operations
(defun |make_filename0|(filearg filetype)
  (let ((filetype (if (symbolp filetype)
                      (symbol-name filetype)
                      filetype)))
    (cond
     ((pathnamep filearg)
      (cond ((pathname-type filearg) (namestring filearg))
            (t (namestring (make-pathname :directory (pathname-directory filearg)
                                          :name (pathname-name filearg)
                                          :type filetype)))))
     ;; Previously, given a filename containing "." and
     ;; an extension this function would return filearg. MCD 23-8-95.
     ((and (stringp filearg) (pathname-type filearg) (null filetype))
          (BREAK)
          filearg)
     ;;  ((and (stringp filearg)
     ;;    (or (pathname-type filearg) (null filetype)))
     ;;     filearg)
     ((and (stringp filearg) (stringp filetype)
           (pathname-type filearg)
           (string-equal (pathname-type filearg) filetype))
      filearg)
     ((consp filearg) (BREAK))
     (t (if (stringp filetype) (setq filetype (intern filetype "BOOT")))
        (let ((ft (or (cdr (assoc filetype |$filetype_table|)) filetype)))
          (if ft
              (concatenate 'string (string filearg) "." (string ft))
              (string filearg)))))))

(defun |make_filename| (filearg)
    (cond
        ((consp filearg)
            (|make_filename0| (car filearg) (cadr filearg)))
        (t (|make_filename0| filearg nil))))

(defun |make_full_namestring| (filearg)
  (namestring (merge-pathnames (|make_filename| filearg))))

(defun |get_directory_list| (ft &aux (cd (get-current-directory)))
  (cond ((member ft '("NRLIB" "DAASE" "EXPOSED") :test #'string=)
           (if (eq |$UserLevel| '|development|)
               (cons cd $library-directory-list)
               $library-directory-list))
        (t (adjoin cd
              (adjoin (namestring (user-homedir-pathname)) $directory-list
                      :test #'string=)
              :test #'string=))))

(defun |probe_name| (file)
  (if (fricas-probe-file file) (namestring file) nil))

(defun |make_input_filename0|(filearg filetype)
   (let*
     ((filename  (|make_filename0| filearg filetype))
      (dirname (pathname-directory filename))
      (ft (pathname-type filename))
      (dirs (|get_directory_list| ft))
      (newfn nil))
    (if (or (null dirname) (eqcar dirname :relative))
        (dolist (dir dirs (|probe_name| filename))
                (when
                 (fricas-probe-file
                  (setq newfn (concatenate 'string dir "/" filename)))
                 (return newfn)))
        (|probe_name| filename))))

(defun |make_input_filename|(filearg)
    (cond
        ((consp filearg)
            (|make_input_filename0| (car filearg) (cadr filearg)))
        (t (|make_input_filename0| filearg nil))))

(defun $FILEP (&rest filearg) (|make_full_namestring| filearg))

(defun $FINDFILE(filespec filetypelist)
  (let ((file-name (if (consp filespec) (car filespec) filespec))
        (file-type (if (consp filespec) (cadr filespec) nil)))
    (if file-type (push file-type filetypelist))
    (some #'(lambda (ft) (|make_input_filename0| file-name ft))
          filetypelist)))

;; ($ERASE filearg) -> 0 if succeeds else 1
(defun $ERASE(&rest filearg)
  (setq filearg (|make_full_namestring| filearg))
  (if (fricas-probe-file filearg)
      (delete-directory filearg)
      1))

#+:GCL
(defun delete-directory (dirname)
   (LISP::system (concat "rm  -r " dirname)))

#+:sbcl
(defun delete-directory (dirname)
   #-:win32 (sb-ext::run-program "/bin/rm" (list "-r" dirname) :search t)
   #+:win32 (obey (concat "rmdir /q /s " "\"" dirname "\""))
  )

#+:cmu
(defun delete-directory (dirname)
   (ext::run-program "rm" (list "-r" dirname))
  )

#+:openmcl
(defun delete-directory (dirname)
   (ccl::run-program "rm" (list "-r" dirname)))

#+:clisp
(defun delete-directory (dirname)
    #-:win32
    (obey (concat "rm -r " dirname))
    #+:win32
    (obey (concat "rmdir /q /s " "\"" dirname "\"")))

#+:ecl
(defun delete-directory (dirname)
  (ext:system (concat "rm -r " dirname)))

#+:poplog
(defun delete-directory (dirname)
    (POP11:sysobey (concat "rm -r " dirname)))

#+:lispworks
(defun delete-directory (dirname)
  (system:call-system (concatenate 'string "rm -r " dirname)))

(defun $REPLACE (filespec1 filespec2)
    ($ERASE (setq filespec1 (|make_full_namestring| filespec1)))
    #-(or :clisp :openmcl :ecl)
    (rename-file (|make_full_namestring| filespec2) filespec1)
    #+(or :clisp :openmcl :ecl)
    (obey (concat "mv " (|make_full_namestring| filespec2) " " filespec1))
 )


(defun $FCOPY (filespec1 filespec2)
    (let ((name1 (|make_full_namestring| filespec1))
          (name2 (|make_full_namestring| filespec2)))
        (copy-lib-directory name1 name2)
))


#+:GCL
(defun copy-lib-directory (name1 name2)
   (makedir name2)
   (LISP::system (concat "sh -c 'cp " name1 "/* " name2 "'")))

#+:sbcl
(defun copy-lib-directory (name1 name2)
   (makedir name2)
   (sb-ext::run-program "/bin/sh" (list "-c" (concat "cp " name1 "/* " name2)))
 )

#+:cmu
(defun copy-lib-directory (name1 name2)
   (makedir name2)
   (ext::run-program "sh" (list "-c" (concat "cp " name1 "/* " name2)))
 )

#+:openmcl
(defun copy-lib-directory (name1 name2)
   (makedir name2)
   (ccl::run-program "sh" (list "-c" (concat "cp " name1 "/* " name2))))

#+(or :clisp :ecl)
(defun copy-lib-directory (name1 name2)
   (makedir name2)
   (OBEY (concat "sh -c 'cp " name1 "/* " name2 "'")))

#+:poplog
(defun copy-lib-directory (name1 name2)
    (makedir name2)
    (POP11:sysobey (concat "cp " name1 "/* " name2)))

#+:lispworks
(defun copy-lib-directory (name1 name2)
   (makedir name2)
   (system:call-system (concat "cp " (concat name1 "/*") " " name2)))

(defvar |$filetype_table|
  '(
    (HELPSPAD . |help|)
    (INPUT . |input|)
    (SPAD . |spad|)
    (BOOT . |boot|)
    (LISP . |lsp|)
    (OUTPUT . |splog|)
    (ERRORLIB . |erlib|)
    (DATABASE . |DAASE|)
   )
)
