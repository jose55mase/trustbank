package com.discord.bot.command;

import com.discord.bot.nitrado.dto.GameServerDto;
import com.discord.bot.nitrado.dto.ServerAction;
import com.discord.bot.nitrado.exception.NitradoApiException;
import com.discord.bot.nitrado.exception.NitradoAuthException;
import com.discord.bot.nitrado.exception.NitradoConnectionException;
import com.discord.bot.nitrado.exception.NitradoNotFoundException;
import com.discord.bot.nitrado.service.NitradoApiClient;

import net.dv8tion.jda.api.Permission;
import net.dv8tion.jda.api.entities.Member;
import net.dv8tion.jda.api.events.interaction.command.SlashCommandInteractionEvent;
import net.dv8tion.jda.api.interactions.InteractionHook;
import net.dv8tion.jda.api.requests.restaction.WebhookMessageEditAction;
import net.dv8tion.jda.api.requests.restaction.interactions.ReplyCallbackAction;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * Unit tests for AbstractServerCommand via RestartCommand.
 * Validates: Requirements 1.2, 1.3, 1.4, 3.1, 3.2, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 6.2, 7.2
 */
@ExtendWith(MockitoExtension.class)
class RestartCommandTest {

    @Mock
    private NitradoApiClient nitradoApiClient;

    @Mock
    private SlashCommandInteractionEvent event;

    @Mock
    private Member member;

    @Mock
    private InteractionHook hook;

    @Mock
    private ReplyCallbackAction replyAction;

    @Mock
    private ReplyCallbackAction deferAction;

    @Mock
    private WebhookMessageEditAction editAction;

    private RestartCommand restartCommand;

    @BeforeEach
    void setUp() {
        restartCommand = new RestartCommand(nitradoApiClient);
    }

    // --- Helper methods ---

    private void setupAdminMember() {
        when(event.getMember()).thenReturn(member);
        when(member.hasPermission(Permission.ADMINISTRATOR)).thenReturn(true);
        when(event.deferReply()).thenReturn(deferAction);
        when(event.getHook()).thenReturn(hook);
        when(hook.editOriginal(anyString())).thenReturn(editAction);
    }

    private void setupEphemeralReply() {
        when(event.reply(anyString())).thenReturn(replyAction);
        when(replyAction.setEphemeral(true)).thenReturn(replyAction);
    }

    // --- Test 1: getName() returns "restart" (Req 1.2) ---

    @Test
    void getNameReturnsRestart() {
        assertEquals("restart", restartCommand.getName());
    }

    // --- Test 2: getDescription() is not empty and is in Spanish (Req 7.2) ---

    @Test
    void getDescriptionIsNotEmptyAndInSpanish() {
        String description = restartCommand.getDescription();
        assertNotNull(description);
        assertFalse(description.isBlank());
        // Verify it contains Spanish keywords
        assertTrue(description.toLowerCase().contains("reinicia") || description.toLowerCase().contains("servidor"),
                "Description should be in Spanish and mention server restart");
    }

    // --- Test 3: User without ADMINISTRATOR receives ephemeral denial (Req 1.4, 3.1) ---

    @Test
    void userWithoutAdminPermissionReceivesEphemeralDenial() {
        when(event.getMember()).thenReturn(member);
        when(member.hasPermission(Permission.ADMINISTRATOR)).thenReturn(false);
        setupEphemeralReply();

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        verify(replyAction).queue();

        String reply = captor.getValue();
        assertEquals("❌ No tienes permisos para ejecutar este comando. Se requiere rol de administrador.", reply);

        // Verify no Nitrado calls were made
        verifyNoInteractions(nitradoApiClient);
    }

    // --- Test 4: Command outside guild (member == null) receives ephemeral response (Req 3.2) ---

    @Test
    void commandOutsideGuildReceivesEphemeralResponse() {
        when(event.getMember()).thenReturn(null);
        setupEphemeralReply();

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(event).reply(captor.capture());
        verify(replyAction).setEphemeral(true);
        verify(replyAction).queue();

        String reply = captor.getValue();
        assertEquals("❌ Este comando solo está disponible en servidores de Discord.", reply);

        verifyNoInteractions(nitradoApiClient);
    }

    // --- Test 5: With 1 server: invokes serverAction with RESTART and responds with success (Req 1.2, 1.3, 4.2) ---

    @Test
    void singleServerInvokesRestartAndRespondsWithSuccess() {
        setupAdminMember();

        GameServerDto server = new GameServerDto(12345, "Mi Servidor DayZ", "192.168.1.1", 2302,
                "started", 10, 60, "chernarusplus", "1.25");
        when(nitradoApiClient.getServers()).thenReturn(List.of(server));

        restartCommand.execute(event);

        verify(nitradoApiClient).serverAction(12345, ServerAction.RESTART);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        String response = captor.getValue();
        assertTrue(response.contains("Mi Servidor DayZ"), "Response should contain the server name");
        assertTrue(response.contains("✅"), "Response should contain success indicator");
    }

    // --- Test 6: With 0 servers: responds with "no servers found" (Req 4.4) ---

    @Test
    void zeroServersRespondsWithNoServersFound() {
        setupAdminMember();

        when(nitradoApiClient.getServers()).thenReturn(Collections.emptyList());

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        String response = captor.getValue();
        assertEquals("❌ No se encontraron servidores DayZ disponibles.", response);

        verify(nitradoApiClient, never()).serverAction(anyInt(), any(ServerAction.class));
    }

    // --- Test 7: With 2+ servers: responds with server list (Req 4.3) ---

    @Test
    void multipleServersRespondsWithServerList() {
        setupAdminMember();

        GameServerDto server1 = new GameServerDto(111, "Servidor Alpha", "10.0.0.1", 2302,
                "started", 5, 60, "chernarusplus", "1.25");
        GameServerDto server2 = new GameServerDto(222, "Servidor Beta", "10.0.0.2", 2302,
                "stopped", 0, 60, "chernarusplus", "1.25");
        when(nitradoApiClient.getServers()).thenReturn(List.of(server1, server2));

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        String response = captor.getValue();
        assertTrue(response.contains("Servidor Alpha"), "Response should contain first server name");
        assertTrue(response.contains("Servidor Beta"), "Response should contain second server name");
        assertTrue(response.contains("111"), "Response should contain first server ID");
        assertTrue(response.contains("222"), "Response should contain second server ID");

        verify(nitradoApiClient, never()).serverAction(anyInt(), any(ServerAction.class));
    }

    // --- Test 8: deferReply() is invoked before Nitrado calls (Req 6.1) ---

    @Test
    void deferReplyIsInvokedBeforeNitradoCalls() {
        setupAdminMember();

        GameServerDto server = new GameServerDto(1, "Test Server", "1.2.3.4", 2302,
                "started", 0, 60, "chernarusplus", "1.25");
        when(nitradoApiClient.getServers()).thenReturn(List.of(server));

        restartCommand.execute(event);

        InOrder inOrder = inOrder(event, deferAction, nitradoApiClient);
        inOrder.verify(event).deferReply();
        inOrder.verify(deferAction).queue();
        inOrder.verify(nitradoApiClient).getServers();
    }

    // --- Test 9: editOriginal() is invoked with the final result (Req 6.2) ---

    @Test
    void editOriginalIsInvokedWithFinalResult() {
        setupAdminMember();

        GameServerDto server = new GameServerDto(99, "Final Server", "5.5.5.5", 2302,
                "started", 20, 60, "chernarusplus", "1.25");
        when(nitradoApiClient.getServers()).thenReturn(List.of(server));

        restartCommand.execute(event);

        verify(event).getHook();
        verify(hook).editOriginal(anyString());
        verify(editAction).queue();
    }

    // --- Test 10: NitradoConnectionException → connection error message (Req 5.1) ---

    @Test
    void connectionExceptionReturnsConnectionErrorMessage() {
        setupAdminMember();

        when(nitradoApiClient.getServers()).thenThrow(
                new NitradoConnectionException("Connection refused", new RuntimeException()));

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        assertEquals("❌ No se pudo contactar con el servicio de Nitrado. Intenta de nuevo más tarde.",
                captor.getValue());
    }

    // --- Test 11: NitradoAuthException → authentication error message (Req 5.2) ---

    @Test
    void authExceptionReturnsAuthErrorMessage() {
        setupAdminMember();

        when(nitradoApiClient.getServers()).thenThrow(new NitradoAuthException("Invalid token"));

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        assertEquals("❌ Error de autenticación con la API de Nitrado. Contacta al administrador del bot.",
                captor.getValue());
    }

    // --- Test 12: NitradoNotFoundException → server not found message (Req 5.3) ---

    @Test
    void notFoundExceptionReturnsNotFoundMessage() {
        setupAdminMember();

        when(nitradoApiClient.getServers()).thenThrow(new NitradoNotFoundException("Not found"));

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        assertEquals("❌ El servidor especificado no fue encontrado en Nitrado.", captor.getValue());
    }

    // --- Test 13: Generic exception → generic error message (Req 5.4) ---

    @Test
    void genericExceptionReturnsGenericErrorMessage() {
        setupAdminMember();

        when(nitradoApiClient.getServers()).thenThrow(new RuntimeException("Unexpected error"));

        restartCommand.execute(event);

        ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
        verify(hook).editOriginal(captor.capture());
        verify(editAction).queue();

        assertEquals("❌ Ocurrió un error inesperado. Intenta de nuevo más tarde.", captor.getValue());
    }
}
