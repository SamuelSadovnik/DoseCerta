# DoseCerta — Spec de Implementação

> Documento único de especificação para implementação do app **DoseCerta** (lembrete de medicamentos e consultas) em Flutter. Ler do início ao fim antes de começar a implementar.

---

## 1. Contexto e papel

Você é o Claude Code. Vai implementar o esqueleto funcional do app DoseCerta a partir de uma pasta vazia. O objetivo **não é produção** — é ter todas as telas navegáveis com mocks no datasource, prontas pra serem refinadas com integração real depois.

**Antes de tudo, leia o documento inteiro.** Este spec contém: setup, arquitetura, design system, inventário de telas, modelo de domínio, mapa de APIs e plano de execução. Não saia implementando tela por tela sem ter lido a parte de design system e de componentes compartilhados.

---

## 2. Setup inicial

A pasta atual está vazia. Execute:

```bash
flutter create --project-name dosecerta --org br.com.dosecerta --platforms=android,ios .
```

Depois **remova** o que não vamos usar:

```bash
rm -rf test/
rm -rf integration_test/
```

Adicione ao `pubspec.yaml` (em `dependencies`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  intl: ^0.19.0
```

Configure também `flutter_localizations` pra suportar pt-BR no `intl`:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

Rode `flutter pub get` ao final.

Substitua **completamente** o `lib/main.dart` gerado pelo `flutter create` — ele será reescrito conforme a seção de execução.

---

## 3. Stack e arquitetura

- **Flutter** estável + Material 3
- **Riverpod** (`flutter_riverpod`) pra state management
- **Sem HTTP real ainda** — datasources retornam mocks com `Future.delayed`
- **Sem persistência local ainda** — sem SharedPreferences, sem Hive

### Clean Architecture em 3 camadas (obrigatório, sem atalhos)

Cada feature segue:

```
features/<feature>/
├── domain/
│   ├── entities/        # Modelos de negócio puros (sem fromJson, sem deps)
│   └── repositories/    # Interfaces abstratas
├── data/
│   ├── models/          # DTOs com fromJson/toJson
│   ├── datasources/     # Interface + impl (HTTP/storage/mock)
│   └── repositories/    # Implementação concreta da interface do domain
└── presentation/
    ├── <screen_name>/
    │   ├── <screen>_page.dart       # Widget
    │   ├── <screen>_view_model.dart # StateNotifier
    │   └── <screen>_state.dart      # Classe imutável com copyWith
    └── providers/                   # Providers Riverpod compartilhados da feature
```

**Regra crítica — Datasource ≠ Repository:**

- **Datasource** sabe sobre HTTP, mock, storage. É a camada que conversa com o mundo externo.
- **Repository concreto** implementa a interface do `domain/`, recebe o Datasource via construtor, mapeia DTO → Entity, trata erros. **Nunca chama HTTP direto.**
- Os dois são camadas separadas. Não mistura.

**Estado:**

- Classes imutáveis com `copyWith`
- ViewModels = `StateNotifier<EstadoX>` expostos via `StateNotifierProvider.autoDispose`
- Para listas que carregam dados, pode usar `AsyncNotifier` quando fizer sentido

**Comentários:** mínimos. Só comente lógica não-óbvia.

**Idioma:** código em inglês, textos visíveis ao usuário em **português**.

---

## 4. Design System

### 4.1 Paleta (`core/theme/app_colors.dart`)

```dart
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFD62828);
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFFCE4E4);   // fundo do círculo do success icon

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF2F2F2);        // inputs e cards de form
  static const Color surfaceAlt = Color(0xFFF5F5F5);     // cards do estoque/home

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textPlaceholder = Color(0xFF9CA3AF);

  // States
  static const Color success = Color(0xFF0F766E);        // verde escuro do "Tudo certo"
  static const Color successLight = Color(0xFFDCFCE7);   // fundo do círculo verde
  static const Color warning = Color(0xFFDC2626);        // mesmo do primary p/ "crítico"
  static const Color error = Color(0xFFDC2626);

  // UI
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
}
```

### 4.2 Tipografia

Usar a fonte padrão do Flutter por enquanto (Roboto). Pesos:
- Títulos de seção (ex: "Início", "Meu Estoque", "Histórico"): `fontSize: 32, fontWeight: w800, color: primary`
- Títulos de modal (ex: "Medicamento", "Consulta" em alertas): `fontSize: 28, fontWeight: w700, color: textPrimary`
- Labels de campo UPPERCASE (ex: "NOME COMPLETO"): `fontSize: 12, fontWeight: w700, letterSpacing: 0.5`
- Labels de campo capitalizado (ex: "Nome do Medicamento"): `fontSize: 14, fontWeight: w600`
- Body: `fontSize: 14-16, w400`
- Botão: `fontSize: 16, w600`

### 4.3 Espaçamentos (`core/theme/app_spacing.dart`)

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double pagePadding = 24;
}
```

### 4.4 Raios de borda

- Inputs e cards de form: `borderRadius: 28` (formato pílula)
- Cards de listagem (estoque, histórico): `borderRadius: 20`
- Hero cards (banner vermelho com imagem): `borderRadius: 24`
- Botões primary: `borderRadius: 28`
- Logo container: `borderRadius: 20`

### 4.5 Tema (`core/theme/app_theme.dart`)

`ThemeData` com Material 3, `ColorScheme.fromSeed(seedColor: primary)`, `scaffoldBackgroundColor: background`. Configurar `inputDecorationTheme` (filled, fillColor: `surface`, border arredondado 28, sem borda quando enabled, borda primary quando focused) e `elevatedButtonTheme` (primary, foreground branco, height 52, radius 28).

---

## 5. Componentes compartilhados (`lib/shared/widgets/`)

Implementar **antes** das features. São reutilizados em várias telas.

### 5.1 `BrandLogo`

Logo (Container vermelho 96x96 com `Icon(Icons.medication, color: white, size: 56)` por enquanto — TODO: trocar por asset PNG quando disponível) + wordmark "DoseCerta" em RichText (Dose em primary, Certa em textPrimary, w800 32). Props: `iconSize`, `fontSize`, `showWordmark`.

### 5.2 `PrimaryButton`

Botão vermelho pílula 52px de altura. Props: `label`, `onPressed`, `isLoading`, `trailingIcon` (default `Icons.arrow_forward`, pode ser nullable). Quando `isLoading`, mostra `CircularProgressIndicator` branco.

### 5.3 `SecondaryButton`

Mesma forma do PrimaryButton mas `backgroundColor: surface`, `foregroundColor: primary`. Sem borda. Usado em "Ir para Início" na tela de sucesso do Responsável.

### 5.4 `LabeledTextField`

Label acima + TextField com `prefixIcon` opcional, `suffixIcon` opcional. Suporta dois estilos via prop `labelStyle`:
- `LabelStyle.normal` — label "Nome do Medicamento" (sentence case, w600, fontSize 14)
- `LabelStyle.uppercase` — label "NOME COMPLETO" (UPPERCASE, w700, fontSize 12, letterSpacing 0.5)

Props: `label`, `hint`, `prefixIcon`, `suffixIcon`, `onChanged`, `obscureText`, `keyboardType`, `errorText`, `labelStyle`.

### 5.5 `HeroCard`

Card vermelho arredondado (radius 24) com imagem de fundo opcional (overlay vermelho semi-transparente sobre asset — usar `Container` com `BoxDecoration.image` + `Color.fromRGBO(214, 40, 40, 0.85)` por cima). Conteúdo: badge UPPERCASE opcional (ex: "SEGURANÇA & CUIDADO") + título grande em branco. Props: `title`, `badge` (opcional), `imageAsset` (opcional, sem asset usa cor sólida), `height` (default 180).

### 5.6 `SuccessIcon`

Círculo verde claro (`successLight`) com check verde escuro (`success`) ao centro. Para a tela "Cadastro Realizado com Sucesso" do **cadastro de conta**, é uma variante: container branco arredondado (radius 24, com leve sombra rosa em volta) contendo um círculo `primaryLight` com check `primaryDark`. Implementar como dois componentes: `SuccessIconGreen` (genérico) e `SuccessIconRed` (cadastro de conta).

### 5.7 `ErrorIcon`

Círculo `primaryLight` (rosado) com X em `primaryDark`. Usado nas telas "Adiamento!" e "Reagendamento!".

### 5.8 `AlertAppBar`

AppBar customizada para as telas de alerta (push notification aberto). Layout: pílula vermelha "Alerta" à esquerda (com ícone do logo pequeno + texto "Alerta") e botão X à direita. Props: `onClose`.

### 5.9 `EmergencyButton`

Botão vermelho pílula full-width com: ícone branco circular com asterisco vermelho à esquerda, "Emergência" em branco bold + "Chamar Responsável" em branco regular pequeno embaixo, ícone de telefone à direita. Props: `onPressed`. Aparece só nas telas de feedback do **Uso Pessoal** (não no Responsável).

### 5.10 `GoogleSignInButton`

Botão branco outline com ícone do Google + "Continuar com Google". Props: `onPressed`.

### 5.11 `OrDivider`

Linha horizontal com "OU" centralizado em `textMuted`.

### 5.12 `ChipSelector<T>`

Wrap de chips selecionáveis (single-select). Chip selecionado: bg `primary`, texto branco. Não selecionado: bg `surface`, texto `textPrimary`. Props: `options: List<ChipOption<T>>`, `selected: T?`, `onChanged: ValueChanged<T>`. `ChipOption` tem `value: T` e `label: String`. Usado em "Grau de Parentesco".

### 5.13 `DoseCertaBottomNav`

Bottom navigation bar com 5 itens: Início, Estoque, Histórico, Consultas, Perfil. Item selecionado: ícone + texto em `primary`. Não selecionado: `textSecondary`. Background branco. Props: `currentIndex`, `onTap`. Usar `BottomNavigationBar` do Material com customização ou criar do zero com `Row`.

### 5.14 `FeedbackPage`

**Componente crítico — tem MUITAS variações de tela usando esse mesmo layout.**

Layout genérico:
- Opcional: botão de voltar arredondado vermelho no topo esquerdo (círculo primary com seta branca)
- Centro: ícone (success verde OU error vermelho)
- Título grande bold (ex: "Tudo certo!", "Adiamento!", "Reagendamento!", "Cadastro Realizado com Sucesso!")
- Subtítulo opcional (ex: "Você tomou a sua dose!", "Seu responsável foi avisado...")
- Espaço
- Botões (1 ou 2)
- Opcional: botão de Emergência no rodapé (só Uso Pessoal)

Props:
```dart
class FeedbackPageConfig {
  final FeedbackIconType iconType; // success | error
  final String title;
  final String? subtitle;
  final List<FeedbackButton> buttons;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showEmergencyButton;
  final VoidCallback? onEmergency;
}

class FeedbackButton {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle style; // primary | secondary
  final IconData? trailingIcon;
}
```

---

## 6. Modelo de domínio (entities)

Coloque cada entity em `features/<feature>/domain/entities/`.

### `User` (auth)
```dart
class User {
  final String id;
  final String name;
  final String email;
  final String? cpf;
  final AccountType accountType; // personal | caregiver
  final String? avatarUrl;
}
```

### `AccountType` (enum em `core/enums/`)
```dart
enum AccountType { personal, caregiver }
```

### `Dependent` (dependents)
```dart
class Dependent {
  final String id;
  final String name;
  final DateTime birthDate;
  final RelationshipType relationship;
  final String? avatarUrl;
  final DependentStatus status; // active | pendingConfirmation | overdue
  final String? statusMessage; // ex: "Medicamentos em dia", "1 dose em atraso"
}

enum RelationshipType { child, mother, father, spouse, other }
enum DependentStatus { active, pendingConfirmation, overdue }
```

### `Medication` (stock)
```dart
class Medication {
  final String id;
  final String name;          // "Paracetamol"
  final String dosage;        // "500mg"
  final MedicationUnit unit;  // tablet | drop | capsule | ml
  final int currentQuantity;
  final int initialQuantity;  // pra calcular % capacidade
  final String frequency;     // "A cada 8 horas"
  final int durationDays;
  final String? dependentId;  // null se for do próprio responsável/uso pessoal
}

enum MedicationUnit { tablet, capsule, drop, ml }

extension MedicationUnitX on MedicationUnit {
  String get plural => switch (this) {
    MedicationUnit.tablet => 'comprimidos',
    MedicationUnit.capsule => 'cápsulas',
    MedicationUnit.drop => 'gotas',
    MedicationUnit.ml => 'ml',
  };
}
```

### `DoseSchedule` (home)
```dart
class DoseSchedule {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;        // "1 comprimido"
  final String? note;         // "Com comida"
  final DateTime scheduledAt;
  final DoseStatus status;    // pending | taken | missed | postponed
  final String? dependentId;
  final String? dependentName;
  final String? dependentAvatarUrl;
}

enum DoseStatus { pending, taken, missed, postponed }
```

### `Appointment` (appointments)
```dart
class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime scheduledAt;
  final String location;
  final AppointmentStatus status; // scheduled | confirmed | completed | cancelled | rescheduled
  final String? doctorAvatarUrl;
  final String? dependentId;
  final String? dependentName;
  final String? dependentAvatarUrl;
}

enum AppointmentStatus { scheduled, confirmed, completed, cancelled, rescheduled }
```

### `HistoryDay` (history)
```dart
class HistoryDay {
  final DateTime date;
  final DayStatus status; // allTaken | someMissed | none
}

enum DayStatus { allTaken, someMissed, none }

class HistorySummary {
  final int dosesTaken;
  final int dosesMissed;
  final List<HistoryDay> days;
  final List<MissedDose> missedDoses;
  final String? dependentId;
  final String? dependentName;
  final String? dependentAvatarUrl;
}

class MissedDose {
  final String medicationName;
  final String dosage;
  final DateTime scheduledAt;
}
```

---

## 7. Inventário de features e telas

Para cada feature, implemente: domain (entities + repository abstrato), data (DTOs + datasource interface + datasource impl com mock + repository concreto), presentation (state + viewmodel + page).

### 7.1 Auth (`features/auth/`)

#### Tela: `LoginPage`
- Centralizada: `BrandLogo`, depois `Container` com `surfaceAlt` (radius 24, padding 20) contendo:
  - `LabeledTextField` "E-mail ou CPF" (label normal sentence case), prefix `Icons.person_outline`, hint "Digite seus dados"
  - `LabeledTextField` "Senha", prefix `Icons.lock_outline`, suffix toggle olho, obscure
  - Link à direita "Esqueceu a senha?" em primary w600
  - `PrimaryButton` "Entrar" com seta
- Abaixo do card: "Ainda não tem acesso?" + `TextButton` "Criar conta" com ícone `add_circle_outline`
- Estado: `identifier`, `password`, `obscurePassword`, `isLoading`, `errorMessage`, `loginSuccess`
- Ações: `onIdentifierChanged`, `onPasswordChanged`, `togglePasswordVisibility`, `submit`
- Navegação: ao logar, vai pra `HomePage`. "Criar conta" → `AccountTypePage`. "Esqueceu a senha?" → TODO (deixar com snackbar "Em breve").

#### Tela: `AccountTypePage`
- Centralizada: `BrandLogo` no topo, espaço grande, dois `PrimaryButton` empilhados:
  - "Uso Pessoal" → `RegisterPage(accountType: personal)`
  - "Responsável" → `RegisterPage(accountType: caregiver)`
- Sem AppBar, com botão `IconButton(Icons.arrow_back)` no topo esquerdo pra voltar pro Login.
- Não precisa de ViewModel (tela puramente navegacional, `StatelessWidget`).

#### Tela: `RegisterPage`
- Recebe `AccountType` por parâmetro. Variações:
  - **personal**: HeroCard título "Uso Pessoal", **mostra checkbox de termos** no fim
  - **caregiver**: HeroCard título "Responsável", **sem checkbox de termos**
- HeroCard com badge "SEGURANÇA & CUIDADO" + título dinâmico
- Campos (`LabeledTextField` com `LabelStyle.uppercase`):
  - "NOME COMPLETO" — prefix `person_outline`, hint "Seu nome"
  - "E-MAIL DE ACESSO" — prefix `mail_outline`, hint "seu@email.com"
  - "SENHA" — prefix `lock_outline`, suffix toggle olho, obscure, hint "••••••••"
- `PrimaryButton` "Finalizar Cadastro" com seta
- Link em primary "Já possuo uma conta de Responsável" (texto fixo, conforme confirmado) → volta pro Login
- `OrDivider`
- `GoogleSignInButton` "Continuar com Google"
- Se `personal`: `TermsCheckbox` "Li e concordo com os Termos de Uso e a Política de Privacidade" (links sublinhados em primary)
- Estado: `name`, `email`, `password`, `obscurePassword`, `acceptedTerms` (só personal), `isLoading`, `errorMessage`, `registerSuccess`
- Validação: para `personal`, botão "Finalizar Cadastro" só habilita se `acceptedTerms == true`
- Navegação ao sucesso: `RegisterSuccessPage(accountType: <mesmo>)`.

#### Tela: `RegisterSuccessPage`
Usar `FeedbackPage` configurado:
- **personal**:
  - `SuccessIconRed`, título "Cadastro Realizado com Sucesso!"
  - 1 botão primary "Ir para Início" → `HomePage`
- **caregiver**:
  - `SuccessIconRed`, título "Cadastro Realizado com Sucesso!"
  - 2 botões: primary "Cadastrar dependente" → `NewDependentPage`; secondary "Ir para Início" → `HomePage`

### 7.2 Home (`features/home/`)

#### Tela: `HomePage`
- AppBar customizada inline (não usar `AppBar` padrão): logo pequeno + "DoseCerta" à esquerda, ícone sino + avatar à direita
- Texto pequeno cinza: data formatada ("Quinta-feira, 24 de Outubro") via `intl` em pt-BR
- Título grande primary "Início"
- Dois cards lado a lado em `Row`:
  - Card 1 (`surfaceAlt`, radius 24): ícone check primary, "4/6", subtítulo "Doses tomadas"
  - Card 2 (`surfaceAlt`, radius 24): ícone relógio `success`, "14:00", subtítulo "Próxima dose"
- Linha "Hoje" + link "Ver tudo" à direita em primary
- Lista de doses do dia (`DoseSchedule[]`), cada item:
  - Lateral esquerda: horário cinza pequeno
  - Card horizontal (cor varia por status):
    - `taken`: opacidade reduzida, check duplo verde à direita
    - `pending` (próxima): borda lateral primary (4px à esquerda), botão "Check" primary à direita
    - `pending` (futura): bg `surfaceAlt`, círculo vazio à direita
    - `missed`: igual taken mas com X vermelho
- **Variante Responsável**: cada item de dose mostra também o avatar circular pequeno do dependente do lado direito (antes do indicador de status)
- `DoseCertaBottomNav` com `currentIndex: 0`
- Estado: `AsyncValue<HomeData>` onde `HomeData` tem `dosesTakenToday`, `dosesTotalToday`, `nextDoseTime`, `todayDoses: List<DoseSchedule>`
- Repository: `HomeRepository.loadHomeData()` retorna `HomeData` (mock)

### 7.3 Stock (`features/stock/`)

#### Tela: `StockListPage`
- AppBar customizada inline (logo + sino + avatar)
- Título primary "Meu Estoque" (Pessoal) ou "Estoque" (Responsável)
- `LabeledTextField` simples (sem label, com hint "Buscar medicamentos..." e prefix `Icons.search`) — TextField ovalado fundo `surface`
- Lista de medicamentos, cada card (radius 20, branco, com sombra leve):
  - Ícone à esquerda (variável por unidade): `Icons.medical_services` (tablet/capsule), `Icons.water_drop` (drop/ml)
  - Nome + dosagem em bold ("Paracetamol (500mg)")
  - Subtítulo: "12 comprimidos restantes" (cinza)
  - Botão `+` à direita (cinza claro, circular, abre modal/sheet pra reabastecer — TODO snackbar "Em breve")
  - Barra de progresso horizontal (cor depende: ≥40% verde-azulado, 20-40% primary, <20% primary com label "ESTOQUE BAIXO")
  - Texto à direita: "CAPACIDADE: XX%"
  - Se crítico (<20%): borda lateral esquerda primary (4px), badge "CRÍTICO" pílula primary com texto branco, botão `+` em primary (vermelho preenchido)
- `PrimaryButton` "Cadastrar Medicamento" → `NewMedicationPage`
- `DoseCertaBottomNav` com `currentIndex: 1`
- Estado: `AsyncValue<List<Medication>>`, filtro por search query

#### Tela: `NewMedicationPage`
- AppBar customizada: X à esquerda (fecha) + título "Novo Medicamento" centralizado bold
- HeroCard "Medicamento" (sem badge)
- Campos `LabeledTextField` com label normal:
  - "Nome do Medicamento" — suffix `Icons.edit_outlined`, hint "Ex: Paracetamol"
  - "Dosagem" — suffix `Icons.straighten`, hint "Ex: 500mg"
  - "Duração" — suffix `Icons.calendar_today_outlined`, hint "Ex: 7 dias"
  - "Frequência" — campo dropdown (use `DropdownButtonFormField` estilizado), opções: "A cada 4 horas", "A cada 6 horas", "A cada 8 horas", "A cada 12 horas", "1x ao dia", "2x ao dia", "3x ao dia"
  - **Apenas Responsável**: "Dependente" — dropdown com lista de dependentes
- `PrimaryButton` "Salvar Medicamento" com `Icons.check_circle`
- Estado: campos + `isLoading` + `success`
- Ao sucesso → `MedicationSuccessPage`

#### Tela: `MedicationSuccessPage`
`FeedbackPage`: `SuccessIconRed`, título "Cadastro Realizado com Sucesso!", botão primary "Ir para Estoque" → `StockListPage` (substitui rota, não empilha).

### 7.4 Appointments (`features/appointments/`)

#### Tela: `AppointmentsListPage`
- AppBar inline padrão
- Título primary "Minhas Consultas" (Pessoal) ou "Consultas" (Responsável)
- Search bar igual ao estoque, hint "Buscar por médico ou especialidade"
- Lista de consultas, cada item (sem card, separadores leves):
  - Avatar circular do médico à esquerda
  - "Dr(a). Nome" bold + especialidade cinza embaixo
  - **Variante Responsável**: avatar pequeno do dependente abaixo do nome do médico
  - Linha com ícone calendário + data + ícone relógio + horário em cinza
  - Badge à direita: "REALIZADA" (verde), "CANCELADA" (cinza), "CONFIRMADA" (primary)
- `PrimaryButton` "Cadastrar Consulta" → `NewAppointmentPage`
- `DoseCertaBottomNav` com `currentIndex: 3`

#### Tela: `NewAppointmentPage`
- AppBar com X + "Nova Consulta"
- HeroCard "Consulta"
- Campos `LabeledTextField`:
  - "Nome do Medico" — suffix edit, hint "Ex: Ana Luiza"
  - "Especialidade" — suffix straighten, hint "Ex: Clínico Geral"
  - "Data" — suffix calendar, hint "Ex: 25 de Outubro de 2026" (abrir `showDatePicker`)
  - "Local" — dropdown, hint "Ex: Hospital Geral Unimed"
  - "Horário" — dropdown, hint "Ex: 14:30" (abrir `showTimePicker`)
  - **Apenas Responsável**: "Dependente" — dropdown
- `PrimaryButton` "Salvar Consulta" com `Icons.check_circle`

#### Tela: `AppointmentSuccessPage`
`FeedbackPage`: `SuccessIconRed`, título "Cadastro Realizado com Sucesso!", botão "Ir para Consultas" → `AppointmentsListPage`.

### 7.5 History (`features/history/`)

#### Tela: `HistoryPage`
- AppBar inline
- Título primary "Histórico"
- Subtítulo: mês/ano ("Outubro 2025") com botões `<` `>` à direita pra navegar entre meses
- Calendário mensal em grid 7 colunas (DOM SEG TER QUA QUI SEX SÁB):
  - Cada célula tem o número do dia + ícone abaixo (check verde, X vermelho, ou nada)
  - Dias do mês anterior em cinza claro
  - Dia atual destacado com círculo `primaryLight` em volta
- Dois cards stats lado a lado:
  - Card 1: ícone check duplo `success`, "124", "DOSES TOMADAS"
  - Card 2: ícone calendário `error`, "02", "DOSES PERDIDAS"
- **Variante Responsável**: a tela mostra **vários blocos de stats**, um por dependente, cada um com avatar circular à esquerda + os dois cards à direita (lado a lado, mas comprimidos)
- Seção "Doses não tomadas":
  - Lista de itens, cada um com borda lateral primary + ícone medicação + nome do remédio + data/hora
- Sem botão flutuante, com `DoseCertaBottomNav` `currentIndex: 2`

### 7.6 Profile (`features/profile/`)

#### Tela: `ProfilePage`
- AppBar inline com ícone configurações (engrenagem primary) à direita + avatar
- Centralizado: avatar grande circular + ícone de edit primary no canto inferior direito do avatar
- Nome "João Silva" bold grande
- Email cinza pequeno
- `SecondaryButton` pequeno "Editar Perfil"
- Lista de itens (cada um: ícone circular `primaryLight` com ícone primary + texto + chevron à direita):
  - Informações Adicionais → ícone `medical_services`
  - Contatos de Emergência → ícone `contact_emergency`
  - Notificações → ícone `notifications_outlined`
  - Tema → ícone `dark_mode_outlined` (com texto "Claro" à direita ao invés de chevron)
  - **Apenas Responsável**: Dependentes → ícone `family_restroom`, badge "2 Ativos" em primaryLight com texto primary à direita + chevron
- Separadores leves entre itens
- `PrimaryButton` "Sair da Conta" com ícone `Icons.logout`
- `DoseCertaBottomNav` com `currentIndex: 4`
- Cada item da lista (exceto Tema) navega para tela placeholder com snackbar "Em breve"
- "Dependentes" navega pra `DependentsListPage`

### 7.7 Dependents (`features/dependents/`)

#### Tela: `DependentsListPage`
- AppBar inline com botão de voltar primary à esquerda + logo "DoseCerta" à direita
- Título primary "Dependentes"
- HeroCard com badge implícita ausente, título grande "Cuidados Compartilhados" + subtítulo branco semi-transparente "Gerencie a saúde de quem você ama com precisão e carinho"
- Lista de dependentes, cada item (sem card, separadores leves):
  - Avatar circular grande à esquerda (com indicador de status: ponto verde, rosa ou laranja no canto inferior direito)
  - Se sem avatar: ícone `Icons.person_search` em círculo `surface`
  - Nome bold + chip pequeno "Pai"/"Mãe"/"Filho"/etc do lado
  - Subtítulo abaixo do nome com ícone de status:
    - Verde + "Medicamentos em dia"
    - Rosa + "Aguardando confirmação"
    - Vermelho + "1 dose em atraso"
  - Chevron à direita
- `PrimaryButton` "Cadastrar Dependente" → `NewDependentPage`
- Sem `DoseCertaBottomNav` (essa é uma sub-tela do Perfil)

#### Tela: `NewDependentPage`
- AppBar com X + "Novo Dependente"
- HeroCard "Dependente"
- Campos `LabeledTextField` com `LabelStyle.uppercase`:
  - "NOME COMPLETO" — suffix `person_outline`, hint "Ex: João"
  - "DATA DE NASCIMENTO" — suffix calendar, hint "00/00/0000" (abrir `showDatePicker`)
- "GRAU DE PARENTESCO" (label uppercase) + `ChipSelector<RelationshipType>`:
  - Filho, Mãe, Pai, Cônjuge, Outro
- `PrimaryButton` "Salvar Dependente" com `Icons.check_circle`
- Ao sucesso → `FeedbackPage` "Cadastro Realizado com Sucesso!" + botão "Ir para Início" → `HomePage`

### 7.8 Alerts (`features/alerts/`)

Telas que aparecem ao abrir uma notificação push. Sempre com `AlertAppBar`. Centro: `BrandLogo` + título do tipo da ação ("Medicamento" ou "Consulta") em bold grande.

#### Tela: `MedicationAlertPage`
- AppBar `Alerta`
- `BrandLogo` + título "Medicamento"
- Card grande `surface` (radius 20):
  - Label "MEDICAÇÃO" centralizado, uppercase, primary
  - Nome do medicamento + dosagem em primary bold grande, centralizado ("Ibuprofeno 400mg")
  - Linha com dois ícones: garfo+colher "Com comida" | gota "200ml água"
- Dois cards pequenos lado a lado:
  - "DOSE ANTERIOR" + "Ontem, 20:30"
  - "ESTOQUE" + "12 cápsulas" (em verde `success`)
- **Botões variam por estado:**
  - **Estado padrão**: `PrimaryButton` "Tomei Agora" com `Icons.check_circle`, depois `SecondaryButton` "Adiar 10 min" com `Icons.snooze` em primary
  - **Após tomar (Pessoal)**: navega pra `FeedbackPage` "Tudo certo! Você tomou a sua dose!" + botão "Voltar"
  - **Após tomar (Responsável avisado)**: variante com avatar do dependente no topo (em vez de só BrandLogo), navega pra `FeedbackPage` "Tudo certo! Seu responsável foi avisado que você concluiu esta ação." + botão "Voltar para o Início" + `EmergencyButton`
  - **Após adiar (Pessoal)**: `FeedbackPage` "Adiamento! Sua dose foi adiada!" + botão "Voltar"
  - **Após adiar (com responsável)**: `FeedbackPage` "Adiamento! Seu responsável foi avisado que você adiou o remédio." + "Voltar para o Início" + `EmergencyButton`
  - **Estado "já adiada"**: card mostra info, botão único `SecondaryButton` "Adiado 10 min" desabilitado com `Icons.snooze`
  - **Estado "já ingerida"** (variante Responsável vendo dose do dependente): botão único primary "Dose ingerida" desabilitado/informativo
- Lógica: ViewModel tem `MedicationAlertState` com `dose: DoseSchedule`, `actionTaken: AlertAction?` (null | taken | postponed), navega ao mudar

#### Tela: `AppointmentAlertPage`
- AppBar `Alerta`
- `BrandLogo` + título "Consulta"
- Card `surface` (radius 20) com avatar do médico à esquerda + label "PROFISSIONAL" primary + nome bold + especialidade cinza
- Dois cards pequenos lado a lado:
  - "Horário" com ícone clock primary + horário grande
  - "Local" com ícone pin primary + nome local
- Botões:
  - `PrimaryButton` "Confirmar Presença" com `Icons.check_circle`
  - `SecondaryButton` "Reagendar" com `Icons.event_repeat` (em primary)
- **Variante Responsável (alerta sobre consulta de dependente)**: igual mas com avatar do dependente no topo + `EmergencyButton` no rodapé
- **Após confirmar (Pessoal)**: `FeedbackPage` "Tudo certo! Presença confirmada!" + "Voltar"
- **Após confirmar (Responsável avisado)**: `FeedbackPage` "Tudo certo! Seu responsável foi avisado que você concluiu esta ação." + "Voltar para o Início" + `EmergencyButton`
- **Após reagendar (Pessoal)**: `FeedbackPage` "Adiamento! Consulta reagendada!" + "Voltar"
- **Após reagendar (Responsável avisado)**: `FeedbackPage` "Reagendamento! Seu responsável foi avisado que você reagendou a consulta." + "Voltar para o Início" + `EmergencyButton`
- **Estado "já confirmada"**: botão único primary "Presença confirmada" desabilitado
- **Estado "já reagendada"** (variante Responsável vendo consulta do dependente): botão único `SecondaryButton` "Reagendada" desabilitado
- ViewModel: `AppointmentAlertState` com `appointment: Appointment`, `actionTaken: AlertAction?`

#### Tela especial: feedback "Sem ações pendentes"
`FeedbackPage`: `SuccessIconGreen`, título "Tudo certo!", subtítulo "Não há nenhuma ação pendente!", **sem botões** (só `EmergencyButton` no rodapé). Acessível via algum atalho ou ao abrir notificação sem ações pendentes — por enquanto, criar uma rota mas não linkar de lugar nenhum (deixa pro Claude Code escolher se cria botão na home pra demo).

---

## 8. Roteamento (`core/routing/`)

Use `Navigator` clássico (não usar GoRouter ainda). Crie um arquivo `app_routes.dart` com constantes de nome de rota e um `RouteFactory` com switch/case que retorna `MaterialPageRoute` para cada tela. Rotas:

```
/login
/account-type
/register (args: AccountType)
/register-success (args: AccountType)
/home
/stock
/new-medication
/medication-success
/appointments
/new-appointment
/appointment-success
/history
/profile
/dependents
/new-dependent
/dependent-success
/alert/medication (args: doseId)
/alert/appointment (args: appointmentId)
/feedback (args: FeedbackPageConfig)
```

`MaterialApp` deve usar `initialRoute: '/login'` e `onGenerateRoute: AppRoutes.onGenerateRoute`.

---

## 9. Tipo de conta global

O tipo de conta (Personal vs Caregiver) influencia várias telas. Crie um provider global:

```dart
final currentAccountTypeProvider = StateProvider<AccountType>((ref) => AccountType.personal);
```

Após login/cadastro, o ViewModel correspondente seta esse provider. Telas que precisam adaptar (Home, Stock, Appointments, History, Profile, formulários) leem com `ref.watch(currentAccountTypeProvider)`.

---

## 10. Mocks nos datasources

Cada datasource impl tem `Future.delayed(Duration(milliseconds: 800))` antes de retornar mocks hardcoded. Use dados realistas baseados nos prints (ex: Paracetamol 500mg, Ibuprofeno 400mg, Vitamina D, Dra. Ana Silva — Cardiologia, etc).

Para listas de dependentes, use:
- João Silva — Pai — Medicamentos em dia
- Maria Souza — Mãe — Aguardando confirmação
- Ricardo Lima — Tio — 1 dose em atraso

---

## 11. APIs NestJS (referência futura)

Não implementar agora — só listar pra alinhar contratos. Coloque em `docs/api_contracts.md` no projeto.

### Auth
- `POST /api/auth/login` — body: `{identifier, password}` → `{accessToken, user}`
- `POST /api/auth/register` — body: `{name, email, password, accountType, acceptedTerms?}` → `{accessToken, user}`
- `POST /api/auth/google` — body: `{idToken, accountType}` → `{accessToken, user}`
- `POST /api/auth/forgot-password` — body: `{identifier}` → `{message}`

### Users
- `GET /api/users/me` → `User`
- `PATCH /api/users/me` — body parcial → `User`

### Dependents
- `GET /api/dependents` → `Dependent[]`
- `POST /api/dependents` — body: `{name, birthDate, relationship}` → `Dependent` (gera código de ativação)
- `GET /api/dependents/:id` → `Dependent`
- `PATCH /api/dependents/:id` — body parcial → `Dependent`
- `DELETE /api/dependents/:id`

### Medications
- `GET /api/medications?dependentId=` → `Medication[]`
- `POST /api/medications` — body: `{name, dosage, unit, initialQuantity, frequency, durationDays, dependentId?}` → `Medication`
- `PATCH /api/medications/:id` — body parcial
- `DELETE /api/medications/:id`
- `POST /api/medications/:id/refill` — body: `{quantity}` → `Medication`

### Doses (Schedule)
- `GET /api/doses/today?dependentId=` → `DoseSchedule[]`
- `POST /api/doses/:id/take` → `{success, decrementedStock}`
- `POST /api/doses/:id/postpone` — body: `{minutes}` → `DoseSchedule`

### Appointments
- `GET /api/appointments?dependentId=` → `Appointment[]`
- `POST /api/appointments` — body: `{doctorName, specialty, scheduledAt, location, dependentId?}` → `Appointment`
- `POST /api/appointments/:id/confirm` → `Appointment`
- `POST /api/appointments/:id/reschedule` — body: `{newScheduledAt}` → `Appointment`
- `DELETE /api/appointments/:id`

### History
- `GET /api/history?month=YYYY-MM&dependentId=` → `HistorySummary`

### Notifications (Emergency)
- `POST /api/notify/caregiver` — body: `{action, payload}` (notifica responsável quando dependente toma/adia/reagenda)
- `POST /api/emergency/call` (botão Emergência do Uso Pessoal — TODO definir comportamento real)

---

## 12. Plano de execução (ordem obrigatória)

1. **Setup**: rodar `flutter create`, remover `test/`, atualizar `pubspec.yaml`, rodar `flutter pub get`.
2. **Core**: criar `core/theme/` (colors, spacing, theme), `core/enums/account_type.dart`, `core/routing/app_routes.dart` (com rotas vazias por enquanto).
3. **Shared widgets**: implementar todos os componentes da seção 5 (BrandLogo, PrimaryButton, SecondaryButton, LabeledTextField, HeroCard, SuccessIconGreen, SuccessIconRed, ErrorIcon, AlertAppBar, EmergencyButton, GoogleSignInButton, OrDivider, ChipSelector, DoseCertaBottomNav, FeedbackPage).
4. **Auth**: domain/data/presentation completos. Login, AccountType, Register (ambas variantes), RegisterSuccess (ambas variantes).
5. **Home**: domain/data/presentation. HomePage com bottom nav funcional.
6. **Stock**: lista + novo medicamento + sucesso.
7. **Appointments**: lista + nova consulta + sucesso.
8. **History**: tela única com calendário e stats.
9. **Profile**: tela com lista de items.
10. **Dependents**: lista + novo dependente + sucesso (acessível via Profile).
11. **Alerts**: medication alert + appointment alert + variantes de feedback.
12. **main.dart**: configurar `MaterialApp` com tema, rotas, locale pt-BR.
13. **`docs/api_contracts.md`**: criar com o conteúdo da seção 11.

Ao final, rodar `flutter analyze` e corrigir warnings. Não rodar testes (foram removidos).

---

## 13. Convenções finais

- **Nunca cortar arquivos** com `// resto aqui`. Sempre completos.
- **Nomes de arquivos** em snake_case, classes em PascalCase.
- **Imports**: usar paths relativos dentro da mesma feature, paths absolutos (com `package:dosecerta/...`) entre features e pra `core/` e `shared/`.
- **Sem dependências de fontes customizadas, assets de imagem reais ou ícones SVG** — use Material Icons e placeholders coloridos para os heros (Container com cor sólida + Icon).
- **Sem testes, sem builds**, conforme solicitado.
- **Telas placeholder** (Esqueceu a senha, Editar Perfil, Informações Adicionais, Contatos de Emergência, Notificações, Tema, Ver tudo da Home): criar simples `Scaffold` com AppBar e texto "Em breve" no centro, ou apenas mostrar `SnackBar` ao toque. Não pular sem implementar nada.

Boa implementação.
