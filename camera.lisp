(in-package #:org.shirakumo.fraf.leaf)

(define-subject camera (trial:2d-camera unpausable)
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
   :target-size (vec (* 8 20) 0)))

(defmethod enter :after ((camera camera) (scene scene))
  (setf (target camera) (unit :player scene))
  (setf (surface camera) (unit :chunk scene)))
(setf (surface (unit :camera T))
      (for:for ((entity over +level+))
        (when (typep entity 'chunk) (return entity))))
(define-handler (camera trial:tick) (ev tt)
  (let ((loc (location camera))
        (int (intended-location camera))
        (surface (surface camera)))
    (unless (active-p (unit :editor +level+))
      (when (target camera)
        (let ((tar (location (target camera))))
          (vsetf int (vx tar) (vy tar))))
      ;; Limit size
      (when surface
        (let ((lx (vx2 (location surface)))
              (ly (vy2 (location surface)))
              (lw (vx2 (bsize surface)))
              (lh (vy2 (bsize surface)))
              (cw (vx2 (target-size camera)))
              (ch (vy2 (target-size camera))))
          (setf (vx int) (clamp (+ lx cw (- lw))
                                (vx int)
                                (+ lx (- cw) lw)))
          (setf (vy int) (clamp (+ ly ch (- lh))
                                (vy int)
                                (+ ly (- ch) lh)))))
      ;; Smooth camera movement
      (let* ((dir (v- int loc))
             (len (max 1 (vlength dir)))
             (ease (clamp 0 (/ (expt len 1.5) 100) 20)))
        (nv* dir (/ ease len))
        (when (< 0.1 (vlength dir))
          (nv+ loc dir))))
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

(define-handler (camera switch-chunk) (ev chunk)
  (setf (surface camera) chunk))

(defmethod project-view ((camera camera) ev)
  (let* ((z (view-scale camera))
         (v (nv- (v/ (target-size camera) (zoom camera)) (location camera))))
    (reset-matrix *view-matrix*)
    (scale-by z z z *view-matrix*)
    (translate-by (vx v) (vy v) 100 *view-matrix*)))
