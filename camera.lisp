(in-package #:org.shirakumo.fraf.leaf)

(define-subject camera (trial:2d-camera)
  ((flare:name :initform :camera)
   (zoom :initarg :zoom :initform 1.0 :accessor zoom)
   (scale :initform 1.0 :accessor view-scale)
   (target-size :initarg :target-size :accessor target-size)
   (target :initarg :target :initform NIL :accessor target)
   (intended-location :initform (vec2 0 0) :accessor intended-location)
   (surface :initform NIL :accessor surface)
   (shake-counter :initform 0 :accessor shake-counter))
  (:default-initargs
   :location (vec 0 0)
   :target-size (vec (* 8 30) 0)))

(defmethod enter :after ((camera camera) (scene scene))
  (setf (target camera) (unit :player scene))
  (setf (surface camera) (unit :chunk scene)))

(define-handler (camera trial:tick) (ev tt)
  (let ((loc (location camera))
        (int (intended-location camera))
        (surface (surface camera))
        (size (target-size camera)))
    (unless (active-p (unit :editor +level+))
      (when (target camera)
        (let ((tar (location (target camera))))
          (vsetf int (vx tar) (vy tar))))
      ;; Limit size
      (when surface
        (setf (vx int) (clamp (+ (vx (location surface))
                                 (vx (target-size camera))
                                 (- (vx (bsize surface))))
                              (vx int)
                              (+ (vx (location surface))
                                 (- (vx (target-size camera)))
                                 (vx (bsize surface)))))
        (setf (vy int) (clamp (+ (vy (location surface))
                                 (vy (target-size camera))
                                 (- (vy (bsize surface))))
                              (vy int)
                              (+ (vy (location surface))
                                 (- (vy (target-size camera)))
                                 (vy (bsize surface))))))
      ;; Smooth camera movement
      (let* ((dir (v- int loc))
             (len (vlength dir))
             (ease (clamp 0 (/ (expt len 1.5) 100) 10)))
        (nv* dir (/ ease len))
        (if (< 1 (vlength dir))
            (nv+ loc dir)
            (vsetf loc (floor (vx loc)) (floor (vy loc))))))
    (when (< 0 (shake-counter camera))
      (decf (shake-counter camera))
      (nv+ loc (vrand -3 +3)))))

(defmethod (setf zoom) :after (zoom (camera camera))
  (setf (view-scale camera) (* (float (/ (width *context*) (* 2 (vx (target-size camera)))))
                               (zoom camera))))

(define-handler (camera resize) (ev)
  (setf (view-scale camera) (* (float (/ (width ev) (* 2 (vx (target-size camera)))))
                               (zoom camera)))
  (setf (vy (target-size camera)) (/ (height ev) (view-scale camera) 2)))

(defmethod project-view ((camera camera) ev)
  (let* ((z (view-scale camera))
         (v (nv- (v/ (target-size camera) (zoom camera)) (location camera))))
    (reset-matrix *view-matrix*)
    (scale-by z z z *view-matrix*)
    (translate-by (vx v) (vy v) 100 *view-matrix*)))