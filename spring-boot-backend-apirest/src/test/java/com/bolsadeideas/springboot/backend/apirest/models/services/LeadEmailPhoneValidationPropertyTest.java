package com.bolsadeideas.springboot.backend.apirest.models.services;

import net.jqwik.api.*;

import java.util.regex.Pattern;

/**
 * Feature: admin-excel-leads-module, Property 8: Validación de formato de email y teléfono
 *
 * Para cualquier string, la validación de email debe aceptar solo strings que cumplan
 * el formato estándar de email (contiene @, dominio válido), y la validación de teléfono
 * debe aceptar solo strings que contengan dígitos y caracteres permitidos (+, -, espacios,
 * paréntesis) con longitud razonable.
 *
 * **Validates: Requirements 7.2**
 */
class LeadEmailPhoneValidationPropertyTest {

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$");
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[\\d+\\-\\s()]{7,20}$");

    // ========== Email Validation Properties ==========

    @Property(tries = 100)
    @Label("Emails con formato válido (user@domain.ext) son aceptados por el regex")
    void validEmailsMatchRegex(@ForAll("validEmails") String email) {
        assert EMAIL_PATTERN.matcher(email).matches()
                : "Expected valid email '" + email + "' to match the email regex";
    }

    @Property(tries = 100)
    @Label("Emails con formato inválido (sin @, sin dominio, etc.) son rechazados por el regex")
    void invalidEmailsDoNotMatchRegex(@ForAll("invalidEmails") String email) {
        assert !EMAIL_PATTERN.matcher(email).matches()
                : "Expected invalid email '" + email + "' to NOT match the email regex";
    }

    // ========== Phone Validation Properties ==========

    @Property(tries = 100)
    @Label("Teléfonos con caracteres permitidos (dígitos, +, -, espacios, paréntesis, 7-20 chars) son aceptados")
    void validPhonesMatchRegex(@ForAll("validPhones") String phone) {
        assert PHONE_PATTERN.matcher(phone).matches()
                : "Expected valid phone '" + phone + "' to match the phone regex";
    }

    @Property(tries = 100)
    @Label("Teléfonos con caracteres inválidos (letras, símbolos especiales, longitud incorrecta) son rechazados")
    void invalidPhonesDoNotMatchRegex(@ForAll("invalidPhones") String phone) {
        assert !PHONE_PATTERN.matcher(phone).matches()
                : "Expected invalid phone '" + phone + "' to NOT match the phone regex";
    }

    // ========== Email Providers ==========

    @Provide
    Arbitrary<String> validEmails() {
        // Generate user part: word characters (letters, digits, underscore), dots, hyphens
        Arbitrary<String> userPart = Arbitraries.strings()
                .withCharRange('a', 'z')
                .withCharRange('0', '9')
                .withChars('_', '.', '-')
                .ofMinLength(1)
                .ofMaxLength(20)
                .filter(s -> s.matches("[\\w.-]+"));

        // Generate domain part: word characters, dots, hyphens
        Arbitrary<String> domainName = Arbitraries.strings()
                .withCharRange('a', 'z')
                .withCharRange('0', '9')
                .withChars('.', '-')
                .ofMinLength(1)
                .ofMaxLength(15)
                .filter(s -> s.matches("[\\w.-]+"));

        // Generate TLD: 2+ alpha characters
        Arbitrary<String> tld = Arbitraries.strings()
                .withCharRange('a', 'z')
                .ofMinLength(2)
                .ofMaxLength(6);

        return Combinators.combine(userPart, domainName, tld)
                .as((user, domain, ext) -> user + "@" + domain + "." + ext);
    }

    @Provide
    Arbitrary<String> invalidEmails() {
        return Arbitraries.oneOf(
                // Missing @ symbol
                Arbitraries.strings()
                        .withCharRange('a', 'z')
                        .withCharRange('0', '9')
                        .withChars('.', '-', '_')
                        .ofMinLength(3)
                        .ofMaxLength(30)
                        .filter(s -> !s.contains("@")),
                // Missing domain after @
                Arbitraries.strings()
                        .withCharRange('a', 'z')
                        .ofMinLength(1)
                        .ofMaxLength(10)
                        .map(s -> s + "@"),
                // Missing TLD (no dot after @)
                Combinators.combine(
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(10),
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(10)
                ).as((user, domain) -> user + "@" + domain),
                // TLD too short (1 char)
                Combinators.combine(
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(10),
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(10),
                        Arbitraries.strings().withCharRange('a', 'z').ofLength(1)
                ).as((user, domain, tld) -> user + "@" + domain + "." + tld),
                // Empty string
                Arbitraries.just(""),
                // Spaces in email
                Combinators.combine(
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(5),
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(5)
                ).as((user, domain) -> user + " @" + domain + ".com"),
                // Double @ symbol
                Combinators.combine(
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(5),
                        Arbitraries.strings().withCharRange('a', 'z').ofMinLength(1).ofMaxLength(5)
                ).as((user, domain) -> user + "@@" + domain + ".com")
        );
    }

    // ========== Phone Providers ==========

    @Provide
    Arbitrary<String> validPhones() {
        // Generate strings with only allowed characters: digits, +, -, space, parens
        // Length between 7 and 20
        return Arbitraries.strings()
                .withCharRange('0', '9')
                .withChars('+', '-', ' ', '(', ')')
                .ofMinLength(7)
                .ofMaxLength(20)
                .filter(s -> PHONE_PATTERN.matcher(s).matches());
    }

    @Provide
    Arbitrary<String> invalidPhones() {
        return Arbitraries.oneOf(
                // Contains letters
                Arbitraries.strings()
                        .withCharRange('0', '9')
                        .withCharRange('a', 'z')
                        .ofMinLength(7)
                        .ofMaxLength(20)
                        .filter(s -> s.chars().anyMatch(Character::isLetter)),
                // Too short (less than 7 chars)
                Arbitraries.strings()
                        .withCharRange('0', '9')
                        .withChars('+', '-', ' ', '(', ')')
                        .ofMinLength(1)
                        .ofMaxLength(6),
                // Too long (more than 20 chars)
                Arbitraries.strings()
                        .withCharRange('0', '9')
                        .withChars('+', '-', ' ', '(', ')')
                        .ofMinLength(21)
                        .ofMaxLength(30),
                // Contains special characters not allowed
                Arbitraries.strings()
                        .withCharRange('0', '9')
                        .withChars('#', '*', '@', '!', '$')
                        .ofMinLength(7)
                        .ofMaxLength(20)
                        .filter(s -> s.chars().anyMatch(c -> "#*@!$".indexOf(c) >= 0)),
                // Empty string
                Arbitraries.just("")
        );
    }
}
