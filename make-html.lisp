(defun matchText (txt)
	(concatenate 
		'string
		"<span class=\"matchText\">"
		txt
		"</span>"))

(defun noMatchText (txt)
	(concatenate 
		'string
		"<span class=\"noMatchText\">"
		txt
		"</span>"))

;;;map lst -> (cadr item) = t or nil
(defun match (lst)
	(let* ((match 0.0)
				 (nomatch 0.0)
	(match-list (mapcar
		#'(lambda (item)
				(if (cadr item)
					(progn
						(incf match (length (car item)))
						(matchText (car item)))
					(progn
						(incf nomatch (length (car item)))
					(noMatchText (car item)))))
		lst)))
		(list match-list
					(float (/ match (+ match nomatch))))))

(defun style ()
	(concatenate 'string 
							 "<style type=\"text/css\">"
							 ".matchText {background-color:#e6bbc4;}"
							 ".noMatchText {}"
							 "</style>"))

(defun result-html (lst)
	(let* ((match-list (match lst))
				(html-list (car match-list))
				(rate (cadr match-list)))
		(apply #'concatenate 'string 
					 (style)
					 (append (list "<span class=\"result\">") html-list (list "</span>") (list "</ br>" "<h2>" (write-to-string  (floor (* rate 100))) "</h2>")))))


(print
	(result-html '(("abc" t) ("cd" nil))))
