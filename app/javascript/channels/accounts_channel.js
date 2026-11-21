import consumer from "channels/consumer"

// Quando o servidor notifica mudanças nas contas (saldo atualizado,
// nova conta), recarregamos a página para trazer o estado novo.
window.App = window.App || {};
App.refresh = () => window.location.reload();

consumer.subscriptions.create("AccountsChannel", {
  connected() {
    // Chamado quando a inscrição está pronta no servidor
  },

  received: () => App.refresh(),
});
