# Coletor Ágil de Patrimônio (Flutter)

Aplicativo Android de alta performance para coleta e catalogação rápida de patrimônios (CPUs e Monitores) através de leitura contínua de QR Code e Códigos de Barras.

---

## 🚀 Destaques e Arquitetura

- **Armazenamento Ultra-Rápido (Hive):**
  - Utiliza banco NoSQL em memória com gravação binária em disco sem travamento de frames (sub-milissegundos por gravação).
  - Prevenção automática de códigos duplicados na mesma secretaria/localidade.
- **Scanner Contínuo com Google ML Kit (`mobile_scanner`):**
  - Leitura rápida de códigos em 60 FPS.
  - Feedback sensorial imediato: vibração tátil nativa (`HapticFeedback`) e alerta sonoro a cada bipe.
- **Fluxo Ágil de 4 Telas:**
  1. **Tela 1: Configuração Inicial** (`Secretaria/Localidade`, seleção `CPU` ou `Monitor`, definição da meta por lote).
  2. **Tela 2: Scanner Rápido** (Câmera 70% com mira, contador em tempo real `✓ X/10`, controle de lanterna).
  3. **Tela 3: Diálogo de Continuidade** (Ao atingir a meta de CPUs, sugere automaticamente coletar Monitores mantendo a mesma localidade).
  4. **Tela 4: Validação & Exportação** (Abas individuais para CPUs e Monitores, arrastar para excluir `Dismissible` e resumo geral).
- **Exportação Dupla Offline:**
  - **TXT:** Relatório textual formatado com cabeçalho, quantidades e horários de leitura.
  - **XLSX:** Planilha Excel com 3 abas estruturadas (`Resumo`, `CPUs` e `Monitores`) gerada 100% em Dart puro (sem dependência de Java/Apache POI).
  - Compartilhamento nativo imediato para WhatsApp, Google Drive, E-mail ou pasta de Downloads (`share_plus`).

---

## 📱 Estrutura de Arquivos

```
lib/
├── main.dart                          # Ponto de entrada, inicialização do Hive e Provider
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Constantes de tipos, limites e caixas Hive
│   ├── theme/
│   │   └── app_theme.dart             # Tema Material 3 com a paleta exata (#1F77D2, #4CAF50, etc.)
│   └── utils/
│       ├── feedback_utils.dart        # Vibração tátil e som instantâneos
│       └── export_utils.dart          # Gerador de relatórios TXT e planilhas XLSX multi-abas
├── data/
│   ├── models/
│   │   └── equipment.dart             # Modelo do Equipamento com serialização Map/Hive
│   └── repositories/
│       └── equipment_repository.dart  # Repositório NoSQL Hive com índices em memória
├── state/
│   └── collection_provider.dart       # Gerenciamento reativo da sessão, anti-duplicidade e contadores
└── ui/
    ├── screens/
    │   ├── config_screen.dart         # Tela 1: Configuração
    │   ├── scanner_screen.dart        # Tela 2: Scanner com Câmera e Overlay
    │   └── validation_screen.dart     # Tela 4: Validação com Abas e Exportação
    └── widgets/
        ├── continuity_dialog.dart     # Tela 3: Modal de transição CPU -> Monitor
        └── equipment_item_tile.dart   # Card com suporte a deslizar para deletar
```

---

## 🛠️ Como Executar e Gerar o APK

### 1. Pré-requisitos
- Flutter SDK instalado (versão `>= 3.0.0`)
- Android SDK configurado

### 2. Instalar Dependências
No terminal do projeto:
```bash
flutter pub get
```

### 3. Executar em modo Debug
Conecte o smartphone Android via USB com depuração ativada e execute:
```bash
flutter run
```

### 4. Gerar o APK de Produção (Release)
Para gerar o arquivo `.apk` otimizado para distribuição:
```bash
flutter build apk --release
```
O arquivo APK gerado estará disponível no caminho:
`build/app/outputs/flutter-apk/app-release.apk`
