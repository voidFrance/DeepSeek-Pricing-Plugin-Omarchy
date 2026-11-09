<div align="center">

<img src="assets/deepseek-mark.svg" alt="DeepSeek Logo" width="80" height="80" />

# DeepSeek Pricing · Omarchy Status Bar Widget

[![Omarchy](https://img.shields.io/badge/Omarchy-Plugin-3b82f6?style=for-the-badge&logo=linux&logoColor=white)](https://omarchy.org)
[![DeepSeek](https://img.shields.io/badge/DeepSeek-API%20Pricing-4f46e5?style=for-the-badge)](https://api-docs.deepseek.com/quick_start/pricing)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(6%2F6)-10b981?style=for-the-badge&logo=node.js&logoColor=white)](tests/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<p align="center">
  <b>Never overpay for tokens again.</b><br>
  A real-time status-bar widget for <a href="https://omarchy.org">Omarchy Linux</a> that monitors DeepSeek API pricing tiers, countdowns, and optimal execution windows right on your panel.
</p>

[✨ Recursos](#-recursos--features) •
[📥 Instalação](#-instalação--installation) •
[⚙️ Configurações](#️-configurações--configuration) •
[🧪 Testes](#-testes) •
[📊 Regras de Preço](#-tabela-de-preços--horários)

---

</div>

## 💡 Sobre o Projeto

A API da **DeepSeek** opera com precificação dinâmica em duas faixas: **Horário de Pico (Peak)** e **Fora de Pico (Off-Peak)** com **50% de desconto** imediato no custo de tokens.

Os horários oficiais são em UTC (01:00–04:00 e 06:00–10:00 UTC, segunda a sexta, exceto feriados nacionais chineses). Em fusos locais (como São Paulo `UTC-3`), calcular manualmente a transição pode gerar erros e gastos desnecessários.

Este widget integra-se nativamente à barra do Omarchy para fornecer feedback visual imediato e contagem regressiva para a próxima janela promocional.

---

## ✨ Recursos / Features

| Recurso | Descrição |
| :--- | :--- |
| 🏷️ **Pill no Painel** | Exibe o ícone oficial da DeepSeek e a taxa atual: `½` (50% off) ou `2×` (pico normal). |
| 💫 **Animação Pulsante** | Halo suave e pulsante ao redor do logo durante o período de desconto (*off-peak*). |
| ⏱️ **Countdown Tooltip** | Hover exibe o tempo exato para a próxima alteração de tarifa e valores atuais por 1M tokens. |
| 📅 **Painel com Timeline** | Clique com o botão esquerdo para abrir o painel detalhado do dia local, dividindo janelas de pico e dicas (*spend now or wait*). |
| 🌐 **Acesso Rápido** | Clique com o botão direito para ir direto à tabela oficial de preços da DeepSeek. |
| 🎨 **Tema Nativo** | QML nativo com `MultiEffect`, adaptando-se automaticamente à paleta de cores e acentos do seu tema Omarchy. |
| 🚀 **Zero Network Overhead** | Sem requisições externas desnecessárias; regras e janelas calculadas com máxima precisão offline via `Model.js`. |

---

## 📥 Instalação / Installation

Para habilitar o plugin no seu painel Omarchy:

```bash
omarchy plugin enable teteu.deepseek-pricing --section right --after omarchy.tray
```

Ou instale a partir deste repositório:

```bash
git clone https://github.com/voidFrance/DeepSeek-Pricing-Plugin-Omarchy.git ~/.config/omarchy/plugins/teteu.deepseek-pricing
omarchy plugin enable teteu.deepseek-pricing
```

---

## ⚙️ Configurações / Configuration

Você pode configurar o plugin através da UI de preferências do painel ou editando o seu `shell.json`:

```json
{
  "plugins": {
    "teteu.deepseek-pricing": {
      "showPro": true,
      "animate": true
    }
  }
}
```

* `showPro` *(boolean, default: `true`)*: Exibe as taxas detalhadas para `deepseek-v4-pro` além do modelo flash padrão.
* `animate` *(boolean, default: `true`)*: Efeito visual pulsante durante a tarifa reduzida (respeita a chave global de animações do Omarchy).

---

## 📊 Tabela de Preços & Horários

### ⏰ Janelas UTC vs Local (São Paulo / UTC-3)
* **Pico 1 (UTC)**: `01:00 – 04:00 UTC` ➔ **22:00 – 01:00 (UTC-3)**
* **Pico 2 (UTC)**: `06:00 – 10:00 UTC` ➔ **03:00 – 07:00 (UTC-3)**
* **Finais de semana & Feriados chineses**: Sempre tarifa reduzida `½` (*Off-peak*).

---

## 🧪 Testes

A lógica de cálculo de fusos, calendários e transições em [`Model.js`](Model.js) é desacoplada e pode ser validada usando a suite de testes nativa do Node.js:

```bash
node --test tests/
```

```
✔ UTC boundaries flip exactly on the hour
✔ weekends are off-peak
✔ next change crosses the night and the weekend
✔ Chinese public holidays suppress peak on weekdays
✔ local timeline covers the whole day and matches the tier
✔ formatters and prices
```

---

## 👤 Autor

Desenvolvido por **[voidFrance](https://github.com/voidFrance)**.

Distribuído sob licença [MIT](LICENSE).
