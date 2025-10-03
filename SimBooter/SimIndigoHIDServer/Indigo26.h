#pragma once
#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>

#pragma pack(push, 4)

//-------------------------------
// Event union
//-------------------------------

typedef union IndigoEvent {

    // --- 1,2 (Keyboard) ---
    struct {
        uint16_t usagePage;
        uint16_t usage;
        bool     down;
        uint32_t flags;
    } keyboard;

    // --- 4 (Translation) ---
    struct {
        double x, y, z;
        uint32_t options;
    } translation;

    // --- 5 (Rotation) ---
    struct {
        double x, y, z;
        uint32_t options;
    } rotation;

    // --- 6 (Scroll / Mouse) ---
    struct {
        double x, y, z;
        uint32_t phase;     // IOHIDEvent phase
        uint8_t momentum;   // scroll momentum
        uint32_t buttonMask;
        double pressure;    // only if mouse-with-pressure
    } scrollOrMouse;

    // --- 7 (Scale) ---
    struct {
        double x, y, z;
        uint32_t options;
    } scale;

    // --- 9 (Velocity) ---
    struct {
        double vx, vy, vz;
        uint32_t options;
    } velocity;

    // --- 11 (Digitizer Finger) ---
    struct {
        uint32_t index;
        uint32_t identity;
        uint32_t eventMask;
        double   x, y, z;
        double   tipPressure;
        double   twist;
        uint32_t inRange;
        uint32_t touch;
        uint32_t options;
        unsigned int field12; // 0x20 + 0x10 + 0x40 = 0x70
        unsigned int field13; // 0x20 + 0x10 + 0x44 = 0x74
        double   quality;
        double   density;
        double   irregularity;
        double   minorRadius;
        double   majorRadius;
        //double accuracy;
    } digitizerFinger;

    // --- 17 (Relative Pointer) ---
    struct {
        double dx, dy, dz;
        uint32_t buttonMask;
        uint32_t identity;
        uint32_t options;
    } relativePointer;

    // --- 23 (Dock Swipe) ---
    struct {
        uint32_t swipeMask;
        double dx, dy, dz;
        uint32_t options;
    } dockSwipe;

    // --- 32 (Force) ---
    struct {
        uint32_t identity;
        uint32_t mask;
        double   level;
        double   secondary;
        uint32_t options;
    } force;

    // --- 35 (Game Controller) ---
    struct {
        double dpad[4];     // up, down, left, right
        double face[4];     // A, B, X, Y
        double shoulder[4]; // L1, L2, R1, R2
        double joystick[4]; // lx, ly, rx, ry
    } gameController;

    // --- 31297 (Button) ---
    struct {
        uint32_t buttonMask;
        uint32_t state;
    } button;

    // --- 300 (Paloma Pose) ---
    struct {
        uint32_t id;
        uint32_t phase;
        float    translation[3];
        float    orientation[4]; // quaternion
    } palomaPose;

    // --- 301–302 (Paloma Collection) ---
    struct {
        uint32_t id;
        uint32_t count;
        // vendor defined + embedded translation/orientation
        // appended as sub-events
    } palomaCollection;

    // --- Fallback / Vendor defined ---
    struct {
        const void *data;
        uint32_t    length;
        uint32_t    options;
    } vendorDefined;

} IndigoEvent;


//-------------------------------
// Indigo payload wrapper
//-------------------------------

typedef struct {
    uint32_t    type;       // 0x00  (same as eventType?)
    uint64_t    timestamp;  // 0x04  mach_absolute_time
    uint32_t    flags;      // 0x0C  IOHIDEvent flags
    union IndigoEvent event; // 0x10+
} IndigoPayload;


//-------------------------------
// Top-level Indigo Mach message
//-------------------------------

typedef struct {
    mach_msg_header_t header;    // 0x00
    uint32_t          innerSize; // 0x18
    uint8_t           eventType; // 0x1C  (see IndigoEventType below)
    // padding here to 0x20
    IndigoPayload payload; // 0x20
} IndigoMessage;


//-------------------------------
// Event type enum
//-------------------------------

typedef enum {
    INDIGO_EVENT_KEYBOARD        = 2,
    INDIGO_EVENT_TRANSLATION     = 4,
    INDIGO_EVENT_ROTATION        = 5,
    INDIGO_EVENT_SCROLL_OR_MOUSE = 6,
    INDIGO_EVENT_SCALE           = 7,
    INDIGO_EVENT_VELOCITY        = 9,
    INDIGO_EVENT_DIGITIZER_FINGER= 11,
    INDIGO_EVENT_REL_POINTER     = 17,
    INDIGO_EVENT_DOCK_SWIPE      = 23,
    INDIGO_EVENT_FORCE           = 32,
    INDIGO_EVENT_GAME_CONTROLLER = 35,
    INDIGO_EVENT_BUTTON          = 31297,
    INDIGO_EVENT_PALOMA_POSE     = 300,
    INDIGO_EVENT_PALOMA_COLLECTION=301,
    INDIGO_EVENT_VENDOR_DEFINED  = 0xFFFF
} IndigoEventType;

#pragma pack(pop)
