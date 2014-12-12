;; Copyright © 2014 FMAP SVERIGE AB

;; This file is part of Eclastic

;; Eclastic is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Lesser General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; Eclastic is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; Lesser General Public License for more details.

;; You should have received a copy of the GNU Lesser General Public
;; License along with Eclastic.  If not, see
;; <http://www.gnu.org/licenses/>.

(in-package :cl-user)
(defpackage :eclastic.aggregations
  (:use :cl
        :eclastic.util)
  (:import-from :yason
                :encode
                :encode-slots
                :encode-object
                :encode-object-element
                :with-array
                :encode-array-elements
                :with-object
                :with-object-element
                :with-output-to-string*
                :*json-output*)
  (:export :<min-or-max>
           :<percentiles>
           :<cardinality>
           :<terms>
           :min*
           :max*
           :percentiles
           :cardinality
           :terms))

(in-package :eclastic.aggregations)

(defclass <aggregation> ()
  ())

(defclass <metric-aggregation> (<aggregation>)
  ())

(defclass <bucket-aggregation> (<aggregation>)
  ())

(defclass <field-or-script-aggregation> (<aggregation>)
  ((aggregate-field :initarg :aggregate-field
                    :reader aggregate-field)
   (aggregate-script :initarg :aggregate-script
                     :reader aggregate-script)))

(defmethod encode-slots progn ((this <field-or-script-aggregation>))
  (when (and (aggregate-field this)
             (aggregate-script this))
    (error "Field and script are mutually exclusive"))
  (unless (or (aggregate-field this)
              (aggregate-script this))
    (error "Either field or script is required")))

(defclass <min-or-max> (<metric-aggregation> <field-or-script-aggregation>)
  ((min-or-max :initarg :min-or-max
               :accessor min-or-max)))

(defmethod encode-slots progn ((this <min-or-max>))
  (with-object-element ((min-or-max this))
    (with-object ()
      (encode-object-element* "field" (aggregate-field this))
      (encode-object-element* "script" (aggregate-script this)))))

(defun min* (&key field script)
  (make-instance '<min-or-max>
                 :min-or-max "min"
                 :aggregate-field field
                 :aggregate-script script))

(defun max* (&key field script)
  (make-instance '<min-or-max>
                 :min-or-max "max"
                 :aggregate-field field
                 :aggregate-script script))

(defclass <percentiles> (<metric-aggregation> <field-or-script-aggregation>)
  ((percents :initarg :percents
             :reader percents)))

(defmethod encode-slots progn ((this <percentiles>))
  (with-object-element ("percentiles")
    (with-object ()
      (encode-object-element* "field" (aggregate-field this))
      (encode-object-element* "script" (aggregate-script this))
      (with-object-element* ("percents" (percents this))
        (with-array ()
          (apply #'encode-array-elements (percents this)))))))

(defun percentiles (&key field script percents)
  (make-instance '<percentiles>
                 :aggregate-field field
                 :aggregate-script script
                 :percents percents))

(defclass <cardinality> (<metric-aggregation> <field-or-script-aggregation>)
  ((precision-threshold :initarg :precision-threshold
                        :reader precision-threshold)
   (rehash :initarg :rehash
           :reader rehash)))

(defmethod encode-slots progn ((this <cardinality>))
  (with-object-element ("cardinality")
    (with-object ()
      (encode-object-element* "field" (aggregate-field this))
      (encode-object-element* "script" (aggregate-script this))
      (encode-object-element* "precision_threshold" (precision-threshold this))
      (encode-object-element* "rehash" (rehash this)))))

(defun cardinality (&key field script precision-threshold rehash)
  (make-instance '<cardinality>
                 :aggregate-field field
                 :aggregate-script script
                 :precision-threshold precision-threshold
                 :rehash (when rehash
                           (ecase rehash
                             (:yes 'yason.true)
                             (:no 'yason.false)))))

(defclass <terms> (<bucket-aggregation> <field-or-script-aggregation>)
  ())

(defmethod encode-slots progn ((this <terms>))
  (with-object-element ("terms")
    (with-object ()
      (encode-object-element* "field" (aggregate-field this))
      (encode-object-element* "script" (aggregate-script this)))))

(defun terms (&key field script)
  (make-instance '<terms>
                 :aggregate-field field
                 :aggregate-script script))
