package com.example.appbinus.config;

import java.time.Instant;

public class OtpEntry {
    private String otp;
    private Instant expiry;
    private String type; // "REGISTER" atau "RESET_PASSWORD"

    public OtpEntry(String otp, Instant expiry, String type) {
        this.otp = otp;
        this.expiry = expiry;
        this.type = type;
    }
}

