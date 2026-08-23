#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "sleep.h"
#include "sha_256.h" // Import our new crypto library

// =====================================================================
// PRODUCTION CONFIGURATION
// =====================================================================
// Address from Vivado Address Editor (Hardcoded for stability in this demo)
#define VAULT_CTRL_BASEADDR  0xA0000000 

// THE "TARGET" HASH
// This represents the correct PIN stored in secure flash.
// In this example, this is the SHA-256 hash of string "123456"
// Hash: 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92
static const uint8_t STORED_HASH[32] = {
    0x8d, 0x96, 0x9e, 0xef, 0x6e, 0xca, 0xd3, 0xc2,
    0x9a, 0x3a, 0x62, 0x92, 0x80, 0xe6, 0x86, 0xcf,
    0x0c, 0x3f, 0x5d, 0x5a, 0x86, 0xaf, 0xf3, 0xca,
    0x12, 0x02, 0x0c, 0x92, 0x3a, 0xdc, 0x6c, 0x92
};

typedef enum {
    STATE_BOOT      = 0,
    STATE_LOCKED    = 1,
    STATE_AUTH      = 2,
    STATE_ACTIVE    = 3,
    STATE_LOCKDOWN  = 4
} VaultState;

VaultState current_state = STATE_BOOT;

// =====================================================================
// CRYPTO HELPERS
// =====================================================================

// Inject the 128-bit key into the FPGA
void inject_key_from_hash(uint8_t *hash_buffer) {
    xil_printf("   [HW] Deriving 128-bit AES Key from SHA-256 Hash...\n\r");
    
    // We take the first 16 bytes (128 bits) of the hash as the key
    // We must cast the byte array into 32-bit words for the AXI bus
    u32 k1 = (hash_buffer[0] << 24) | (hash_buffer[1] << 16) | (hash_buffer[2] << 8) | hash_buffer[3];
    u32 k2 = (hash_buffer[4] << 24) | (hash_buffer[5] << 16) | (hash_buffer[6] << 8) | hash_buffer[7];
    u32 k3 = (hash_buffer[8] << 24) | (hash_buffer[9] << 16) | (hash_buffer[10] << 8) | hash_buffer[11];
    u32 k4 = (hash_buffer[12] << 24) | (hash_buffer[13] << 16) | (hash_buffer[14] << 8) | hash_buffer[15];

    Xil_Out32(VAULT_CTRL_BASEADDR + 0x00, k1);
    Xil_Out32(VAULT_CTRL_BASEADDR + 0x04, k2);
    Xil_Out32(VAULT_CTRL_BASEADDR + 0x08, k3);
    Xil_Out32(VAULT_CTRL_BASEADDR + 0x0C, k4);
    
    // Enable Engine
    Xil_Out32(VAULT_CTRL_BASEADDR + 0x10, 0x00000001); 
    
    xil_printf("   [HW] Key Injected. Pipeline ACTIVE.\n\r");
}

int authenticate_user(char* input_pin) {
    uint8_t current_hash[32];
    SHA256_CTX ctx;

    xil_printf("\n\r   [AUTH] Hashing Input PIN: %s ...\n\r", input_pin);

    // Calculate SHA-256
    sha256_init(&ctx);
    sha256_update(&ctx, (uint8_t*)input_pin, strlen(input_pin));
    sha256_final(&ctx, current_hash);

    // Verify against stored hash
    // We use a constant-time comparison logic in production, but memcmp is fine for POC
    if (memcmp(current_hash, STORED_HASH, 32) == 0) {
        xil_printf("   [AUTH] MATCH CONFIRMED.\n\r");
        inject_key_from_hash(current_hash);
        return 1;
    } else {
        xil_printf("   [AUTH] HASH MISMATCH. Access Denied.\n\r");
        return 0;
    }
}

// =====================================================================
// MAIN LOOP
// =====================================================================
int main() {
    Xil_ICacheEnable();
    Xil_DCacheEnable();

    xil_printf("\n\r===========================================\n\r");
    xil_printf("      AEGIS KEYMASTER v2.0 (SHA-256)      \n\r");
    xil_printf("===========================================\n\r");

    current_state = STATE_LOCKED;

    // SIMULATION LOOP
    // We simulate a failed login, then a successful one.
    // DEMONSTRATION ONLY. DO NOT USE HARDCODED KEYS IN PRODUCTION.
    
    char* test_pin_wrong = "000000";
    char* test_pin_correct = "123456";

    while (1) {
        switch (current_state) {
            case STATE_LOCKED:
                xil_printf("\n\r[UI] System Locked. Waiting for Credentials...\n\r");
                
                // Simulation: Try wrong pin first
                sleep(1);
                xil_printf("[USER] User entered PIN: %s\n\r", test_pin_wrong);
                if (authenticate_user(test_pin_wrong)) {
                    current_state = STATE_ACTIVE;
                } else {
                    xil_printf("[SYS] Remaining Attempts: 2\n\r");
                }

                // Simulation: Try correct pin
                sleep(2);
                xil_printf("[USER] User entered PIN: %s\n\r", test_pin_correct);
                if (authenticate_user(test_pin_correct)) {
                    current_state = STATE_ACTIVE;
                }
                break;

            case STATE_ACTIVE:
                // Infinite Loop
                sleep(5);
                xil_printf("[SYS] SECURE SESSION ACTIVE.\n\r");
                break;
            case STATE_BOOT:
            case STATE_AUTH:
            case STATE_LOCKDOWN:
              break;
            }
    }
    return 0;
}
