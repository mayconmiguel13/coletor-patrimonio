# Esboço Visual das Telas

## Tela 1: Configuração Inicial

```
┌─────────────────────────────────────┐
│   COLETA DE EQUIPAMENTOS            │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Secretaria/Localidade:          ││
│  │                                 ││
│  │ [________________]              ││  ← Campo texto
│  │ Ex: Secretaria TI, Sala 201     ││
│  └─────────────────────────────────┘│
│                                     │
│  Tipo de Equipamento:               │
│                                     │
│  ◉ CPU         ○ Monitor            │  ← Radio buttons
│                                     │
│                                     │
│                                     │
│                                     │
│                ┌─────────────────┐  │
│                │ Iniciar Coleta  │  │  ← Botão (desabilitado se vazio)
│                └─────────────────┘  │
└─────────────────────────────────────┘
```

---

## Tela 2: Scanner de Coleta

```
┌─────────────────────────────────────┐
│ Secretaria TI  |  CPU               │  ← Info no topo
│ ✓ 1/10 CPUs coletados               │  ← Contador
├─────────────────────────────────────┤
│                                     │
│                                     │
│     ┌─────────────────────────────┐ │
│     │                             │ │
│     │   📷 CÂMERA AO VIVO         │ │  ← Preview câmera (70% da tela)
│     │   (Aponte para QR code)     │ │
│     │                             │ │
│     │     🎯 [QR code detected]   │ │  ← Feedback quando detecta
│     │                             │ │
│     └─────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐ │
│  │ ✓ Confirmar  │  │ ← Descartar  │ │  ← Botões
│  └──────────────┘  └──────────────┘ │
│                                     │
│            [⊘ Cancelar Tudo]        │  ← Link/botão menor
│                                     │
└─────────────────────────────────────┘
```

**Fluxo:** Após ler código → Som/Vibração → Contador incrementa → Câmera pronta para próximo

---

## Tela 3: Dialog de Continuidade

```
┌─────────────────────────────────────┐
│                                     │
│        ✓ SUCESSO!                   │
│                                     │
│    Coleta de CPUs Concluída         │
│                                     │
│    Total Coletado: 10 equipamentos  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│   Deseja coletar MONITORES          │
│   para a mesma localidade?          │
│   (Secretaria TI)                   │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ ✓ Sim, coletar monitores        ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ ✗ Não, ir para validação        ││
│  └─────────────────────────────────┘│
│                                     │
│       Cancelar e descartar tudo     │
│                                     │
└─────────────────────────────────────┘
```

**Lógica:**
- Sim → Volta Tela 2, agora com tipo "Monitor", contador zera
- Não → Vai para Tela 4
- Cancelar → Volta Tela 1, descarta tudo

---

## Tela 4: Validação e Exportação

### Layout com Abas

```
┌─────────────────────────────────────┐
│  VALIDAÇÃO - Secretaria TI          │
├─────────────────────────────────────┤
│                                     │
│  📊 RESUMO:                         │
│  ├─ CPUs: 10 ✓                      │
│  └─ Monitores: 10 ✓                 │
│                                     │
│  ─── [CPUs]  [Monitores] ───        │  ← Abas
│                                     │
│  CPUS:                              │
│                                     │
│  ✓ QR-CPU-001    [⊘]                │
│  ✓ QR-CPU-002    [⊘]                │
│  ✓ QR-CPU-003    [⊘]                │
│  ... (scroll)                       │
│  ✓ QR-CPU-010    [⊘]                │  ← [⊘] = deletar
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────┐  ┌──────────────┐ │
│  │ 📄 TXT       │  │ 📊 XLSX      │ │  ← Botões exportar
│  └──────────────┘  └──────────────┘ │
│                                     │
│  ┌──────────────┐                   │
│  │ ← Voltar     │                   │  ← Voltar editar
│  └──────────────┘                   │
│                                     │
└─────────────────────────────────────┘
```

### Aba Monitores (igual, mas com monitores)

```
┌─────────────────────────────────────┐
│  VALIDAÇÃO - Secretaria TI          │
├─────────────────────────────────────┤
│                                     │
│  📊 RESUMO:                         │
│  ├─ CPUs: 10 ✓                      │
│  └─ Monitores: 10 ✓                 │
│                                     │
│  ─── [CPUs]  [Monitores] ───        │  ← ABA ATIVA: Monitores
│                                     │
│  MONITORES:                         │
│                                     │
│  ✓ MON-L27-001      [⊘]             │
│  ✓ MON-L27-002      [⊘]             │
│  ✓ MON-L27-003      [⊘]             │
│  ... (scroll)                       │
│  ✓ MON-L27-010      [⊘]             │
│                                     │
├─────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐ │
│  │ 📄 TXT       │  │ 📊 XLSX      │ │
│  └──────────────┘  └──────────────┘ │
│                                     │
│  ┌──────────────┐                   │
│  │ ← Voltar     │                   │
│  └──────────────┘                   │
│                                     │
└─────────────────────────────────────┘
```

---

## Estados de Feedback Visual

### Ao ler QR code com sucesso:

```
Tela 2:
Antes → Depois:

✓ 0/10 CPUs     →    ✓ 1/10 CPUs
[câmera normal] →    [câmera + flash verde 1seg]
[silêncio]      →    [som + vibração]
```

### Ao tentar ler código duplicado:

```
⚠️ Código já foi coletado!
[câmera espera 2 segundos antes de limpar]
```

### Ao exportar:

```
✓ Arquivo salvo em:
/Downloads/coleta_Secretaria_TI_1705326000.txt
[Botão: Compartilhar / OK]
```

---

## Cores e Tema

**Material Design 3 - Profissional**

```
Primária: #1F77D2 (Azul)
Secundária: #616161 (Cinza)
Sucesso: #4CAF50 (Verde)
Erro/Aviso: #FF9800 (Laranja)
Fundo: #F5F5F5 (Cinza claro)
Texto: #212121 (Preto)
```

**Dark Mode:** Inverter cores mantendo contraste

---

## Interações Esperadas

| Ação | Feedback |
|------|----------|
| Clicar "Iniciar Coleta" (vazio) | Botão desabilitado (cinza) |
| Ler QR code | Som + Vibração + Contador ↑ |
| Ler código duplicado | ⚠️ Aviso por 2 segundos |
| Clicar "Exportar TXT" | Toast: "Arquivo salvo em Downloads" |
| Clicar "Exportar XLSX" | Toast: "Arquivo salvo em Downloads" |
| Deslizar item para esquerda | Opção de deletar aparece |
| Voltar sem salvar | Pergunta: "Descartar dados?" |

---

## Dimensões Responsivas

- **Pequenas (4"):** 1 coluna, botões gigantes
- **Médias (5.5"):** Layout ideal
- **Grandes (6.5"+):** Margem maior, lista com 2 colunas (opcional)

---

## Acessibilidade

- Todos os botões ≥ 48dp de toque
- Contraste texto ≥ 4.5:1
- Suporte a TalkBack (leitor de tela)
- Descrições alt para ícones

