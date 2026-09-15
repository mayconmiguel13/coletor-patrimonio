# Prompt: APK Ágil para Coleta de Equipamentos

## Objetivo
Aplicativo Android super rápido para coletar QR codes/códigos de barras de equipamentos, com fluxo otimizado e validação antes de exportar.

---

## Tela 1: Configuração Inicial (Principal)

**Componentes:**
- Campo de texto: **"Secretaria/Localidade"** (obrigatório)
  - Ex: Secretaria de TI, Almoxarifado, Sala 201
  
- **Seleção de Tipo de Equipamento:**
  - Botão radio ou segmented control
  - Opções: `CPU` | `Monitor`

- Botão grande: **"Iniciar Coleta"** (ativado apenas com localidade + tipo preenchidos)

---

## Tela 2: Scanner (Coleta Rápida)

**Elementos:**
- Exibir no topo: `Localidade: [secretaria]` | `Tipo: [CPU]`
- **Câmera ao vivo** ocupando 70% da tela
- Ao ler QR code/código de barras:
  - Som/vibração de confirmação
  - Mostrar código lido por 1 segundo
  - Contador: `✓ 1/10 CPUs coletados`
  - **Limpar câmera automaticamente** para próxima leitura

**Botões inferiores:**
- **"✓ Confirmar e Próximo Equipamento"** (ou auto-avançar após leitura)
- **"← Voltar"** (descarta leitura atual)
- **"⊘ Cancelar Tudo"** (volta para Tela 1)

**Validação:**
- Impedir leitura de códigos duplicados (aviso)
- Após ler todos, ir para próxima tela automaticamente

---

## Tela 3: Pergunta de Continuidade

**Cenário:** Após coletar 10 CPUs, exibir:

```
✓ Coleta de CPUs Concluída!
Total: 10 equipamentos

Deseja coletar MONITORES 
para a mesma localidade?
```

**Botões:**
- **"Sim, coletar monitores"** → Volta para Tela 2 (agora coletando Monitores)
- **"Não, ir para validação"** → Vai para Tela 4
- **"Cancelar e descartar"** → Volta para Tela 1

**Lógica:**
- Se clicar "Sim": Tipo muda para Monitor, contador zera, câmera reinicia
- Localidade permanece a mesma

---

## Tela 4: Validação e Resumo

**Layout:**
- **Resumo no topo:**
  ```
  Secretaria: [localidade]
  └─ CPUs: 10 equipamentos
  └─ Monitores: 10 equipamentos
  ```

- **Listagem em abas ou seções:**
  
  **Aba 1: CPUs**
  - Lista com itens deslizáveis
  - Cada item: `✓ [código lido] [data/hora]`
  - Botão para deletar individual

  **Aba 2: Monitores**
  - Mesma estrutura

- **Botões inferiores:**
  - **"Exportar TXT"** → Gera arquivo `.txt` simples
  - **"Exportar XLSX"** → Gera arquivo Excel com abas por tipo
  - **"Voltar"** → Editar/adicionar mais equipamentos

---

## Estrutura de Dados Armazenada

**Tabela: equipamentos**
```
id | localidade | tipo | codigo_lido | timestamp | sincronizado
1  | Secretaria TI | CPU | QR-001 | 2024-01-15 10:30 | false
2  | Secretaria TI | CPU | QR-002 | 2024-01-15 10:31 | false
...
11 | Secretaria TI | Monitor | MON-001 | 2024-01-15 10:45 | false
```

---

## Formatos de Exportação

### TXT (Simples e direto)
```
RELATÓRIO DE COLETA DE EQUIPAMENTOS
=====================================
Localidade: Secretaria de TI
Data: 15/01/2024

CPUS (10 equipamentos):
- QR-001 (10:30)
- QR-002 (10:31)
...

MONITORES (10 equipamentos):
- MON-001 (10:45)
- MON-002 (10:46)
...

Total: 20 equipamentos
```

### XLSX (Excel com abas)
- **Aba 1: Resumo**
  - Localidade
  - Total CPUs
  - Total Monitores
  - Data de coleta

- **Aba 2: CPUs**
  - ID | Código | Timestamp

- **Aba 3: Monitores**
  - ID | Código | Timestamp

---

## Requisitos Técnicos

### Stack
- **Linguagem:** Kotlin
- **Arquitetura:** MVVM + LiveData ou Compose
- **Banco:** SQLite (Room)
- **Scanner:** ML Kit ou ZXing
- **Câmera:** CameraX
- **Exportação:** Apache POI (XLSX), File I/O (TXT)

### Permissões
- CAMERA
- READ/WRITE_EXTERNAL_STORAGE (para exportar)

---

## Fluxo Simplificado

```
┌─────────────────────┐
│ Tela 1: Config      │ (Localidade + Tipo)
│ "Iniciar Coleta"    │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│ Tela 2: Scanner     │ (Lê 10 códigos)
│ (CPU)               │
└──────────┬──────────┘
           │
┌──────────▼──────────────────────┐
│ Tela 3: Pergunta                │
│ "Coletar Monitores?"            │
└──┬──────────────────────┬───────┘
   │ SIM                  │ NÃO
   │                      │
   ▼                      │
┌──────────────────┐      │
│ Tela 2: Scanner  │      │
│ (Monitor)        │      │
└──────────┬───────┘      │
           │              │
           └──────┬───────┘
                  │
         ┌────────▼────────┐
         │ Tela 4: Validar │
         │ + Exportar      │
         └─────────────────┘
```

---

## Checklist de Desenvolvimento

- [ ] Tela 1: Input localidade + seleção tipo
- [ ] Tela 2: Câmera com scanner automático
- [ ] Contador de equipamentos coletados
- [ ] Validação de duplicatas
- [ ] Tela 3: Dialog de continuidade
- [ ] Tela 4: Listagem com validação
- [ ] Exportação TXT
- [ ] Exportação XLSX
- [ ] Banco de dados SQLite
- [ ] Testes em dispositivos reais

---

## Observações

- **Agilidade:** Sem telas desnecessárias, fluxo linear
- **UX:** Feedback visual rápido (som, vibração, contador)
- **Offline:** Tudo funciona sem internet
- **Segurança:** Validar duplicatas, salvar automaticamente
- **Exportação:** Arquivos salvos em Downloads acessível ao usuário

