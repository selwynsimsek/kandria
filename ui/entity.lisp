(in-package #:org.shirakumo.fraf.leaf)

(alloy:define-widget entity-widget (sidebar)
  ((entity :initarg :entity :initform NIL :accessor entity
           :representation (alloy:label))))

(alloy:define-subcomponent (entity-widget region) ((name (unit 'region T)) alloy:label))
(alloy::define-subbutton (entity-widget move) ()
  (issue +world+ (make-instance 'move-entity)))
(alloy::define-subbutton (entity-widget resize) ()
  (issue +world+ (make-instance 'resize-entity)))
(alloy::define-subbutton (entity-widget clone) ()
  (issue +world+ (make-instance 'clone-entity)))
(alloy::define-subbutton (entity-widget delete) ()
  (leave (entity entity-widget) (unit 'region T)))

(alloy:define-subcontainer (entity-widget layout)
    (alloy:vertical-linear-layout)
  region entity
  (alloy:build-ui
   (alloy:grid-layout
    :col-sizes '(T T T T) :row-sizes '(30) :cell-margins (alloy:margins 1 0 0 0)
    move resize clone delete)))

(alloy:define-subcontainer (entity-widget focus)
    (alloy:focus-list)
  move resize clone delete)