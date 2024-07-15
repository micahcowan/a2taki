#include <math.h>
#include <stdio.h>

int
main(void) {
    double start=24.;
        // bounce-in line starts outside the view, all the way to the
        // right (so, "25th" column).
    double adur=.5;
        // time to hit the left wall first time (must be less than dur,
        // and > 0.5 * dur)
    double dur=1.;
        // total time for the animation to take
    double bdur = dur - adur;
    double fps=30.;
        // assume the animation is this frames/per second

    /*
       The formula for what column the line should be printed from
       as a function of time, is:
      
        col = start - (t*x)^2
      
       (where x is a scaling factor)
      
       We know col is 0 when t = adur, so
      
        0 = start - (adur*x)^2
      
       Solve for x to find the scaling factor, given start and adur
      
        start = (adur*x)^2
        sqrt(start) = adur*x
        x = sqrt(start)/adur
        x^2 = start/(adur^2)

       The velocity here, in columns per sec, is -2 * x^2 * t.
       (By differentiating for t.)
     */
    double xsqr = start/(adur*adur);
    double x    = sqrt(xsqr);

    /*
       For the bounce, we have (dur-adur, = bdur) time. To find the
       initial velocity for the bounce (after the text has hit the left edge),
       that is, the velocity at t = 0 (we restart the timer at bounce),
       we need the positive starting velocity such that when t = bdur/2,
       that velocity is zero.

        vel = bvel0 - 2 * x^2 * bdur/2 = 0
        bvel0 = 2 * x^2 * bdur/2

       This gives us the curve for the bounce (by integration):

        col = bvel0 * t - (x * t)^2

       Don't need to worry about an added constant, bc we know col = 0
       at t = 0 (again, t is now "start of bounce", not "start of animation")
     */
    double bvel0 = 2 * xsqr * bdur/2;

    unsigned int numFrames = dur * fps + 1;
        // + 1 is to guarantee we have at least one final frame at
        //  column 0 (.byte value 1)
    unsigned int numAFrames = adur * fps;
    unsigned int numBFrames = numFrames - numAFrames;

    printf("\
; Generating %u frames at %u fps, to last %f seconds.\n",
            numFrames, (unsigned int)fps, dur);
    printf("\
; Time to reach left edge the first time: %f seconds (%u frames).\n",
            adur, numAFrames);
    printf("\
; Time to reach left edge the second time: %f seconds (%u frames).\n",
            bdur, numBFrames);

    const unsigned int framesPerLine = 8;
    unsigned int framesLeft = 0;
    printf("\n\
; Slide-left frames:\n");
    for (unsigned int i = 0; i != numAFrames; ++i) {
        if (!framesLeft) {
            framesLeft = 8;
            printf("\n.byte ");
        } else {
            printf(", ");
        }
        double t = i / fps;
        unsigned int col = start - (t * t * xsqr);
        if (col < 0) col = 0;
        printf("%u", col + 1); // add one so we can zero-terminate the list!
        --framesLeft;
    }
    framesLeft = 0;
    printf("\n\n\
; Bounce frames:\n");
    for (unsigned int i = 0; i != numBFrames; ++i) {
        if (!framesLeft) {
            framesLeft = 8;
            printf("\n.byte ");
        } else {
            printf(", ");
        }
        double t = i / fps;
        unsigned int col = bvel0 * t - (t * t * xsqr);
        if (col < 0) col = 0;
        printf("%u", col + 1); // add one so we can zero-terminate the list!
        --framesLeft;
    }
    printf("\n\n.byte 0\n");
}
