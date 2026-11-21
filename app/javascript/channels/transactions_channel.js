import consumer from "channels/consumer"

// Quando o servidor notifica novas transações no extrato, recarregamos a página.
consumer.subscriptions.create("TransactionsChannel", {
  received: () => window.App.refresh && window.App.refresh(),
});
