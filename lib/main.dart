// ============================================================
// EcoHábitos - App de hábitos sustentáveis
// Autor: Gustavo Steven Lima Sousa
// ============================================================
// Ideia do app: o usuário escolhe hábitos sustentáveis para fazer
// (ex.: tomar banho curto, usar sacola reutilizável) e marca quando
// cumpre. Cada hábito vale uma quantidade de CO2 que deixou de ser
// emitido, e o app soma isso para mostrar o impacto da pessoa.
// ============================================================

import 'dart:convert'; // usado para transformar a lista em texto (JSON) e voltar
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // guarda dados no celular

// Função que inicia o app. O Flutter começa a execução por aqui.
void main() {
  runApp(const EcoHabitosApp());
}

// Meta semanal de CO2 evitado, em kg (valor fixo escolhido por mim).
const double metaSemanalKg = 5.0;

// Hábitos que o usuário pode escolher ao adicionar (nome -> kg de CO2 evitado).
// Os valores são estimativas simples, só para o cálculo do app.
const Map<String, double> habitosDisponiveis = {
  'Tomar banho de 5 minutos': 0.5,
  'Usar sacola reutilizável': 0.1,
  'Ir a pé ou de bicicleta': 1.0,
  'Separar o lixo reciclável': 0.3,
  'Desligar aparelhos da tomada': 0.2,
  'Comer uma refeição sem carne': 1.5,
  'Pegar carona solidária': 0.8,
};

// Dicas que aparecem na segunda tela (uma diferente por dia da semana).
const List<String> dicas = [
  'Feche a torneira enquanto escova os dentes.',
  'Leve sua própria garrafa de água para a universidade.',
  'Apague as luzes ao sair de uma sala.',
  'Prefira usar a escada em vez do elevador.',
  'Doe roupas que você não usa mais.',
  'Evite imprimir papéis sem necessidade.',
  'Compre só a quantidade de comida que você vai consumir.',
];

// ------------------------------------------------------------
// Classe que representa UM hábito da lista
// ------------------------------------------------------------
class Habito {
  String nome; // nome do hábito
  double co2; // quanto de CO2 (kg) ele evita
  bool concluido; // true = já foi feito

  Habito({required this.nome, required this.co2, this.concluido = false});

  // Transforma o hábito em um Map (chave -> valor) para poder virar JSON.
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'co2': co2, 'concluido': concluido};
  }

  // Faz o caminho inverso: pega um Map (lido do JSON) e monta o Habito.
  factory Habito.fromMap(Map<String, dynamic> mapa) {
    return Habito(
      nome: mapa['nome'],
      co2: (mapa['co2'] as num).toDouble(),
      concluido: mapa['concluido'],
    );
  }
}

// ------------------------------------------------------------
// Widget raiz do app: define o tema e a primeira tela
// ------------------------------------------------------------
class EcoHabitosApp extends StatelessWidget {
  const EcoHabitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoHábitos',
      debugShowCheckedModeBanner: false, // tira a faixa "debug"
      theme: ThemeData(
        colorSchemeSeed: Colors.green, // cor verde combina com sustentabilidade
        useMaterial3: true,
      ),
      home: const TelaPrincipal(),
    );
  }
}

// ------------------------------------------------------------
// TELA PRINCIPAL: lista de hábitos
// ------------------------------------------------------------
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  // Lista que guarda todos os hábitos na memória enquanto o app está aberto.
  List<Habito> habitos = [];

  // Chave (nome) usada para guardar a lista no armazenamento do celular.
  static const String chaveArmazenamento = 'lista_habitos';

  // initState roda uma vez, quando a tela é criada (ao abrir o app).
  @override
  void initState() {
    super.initState();
    carregarHabitos(); // ao abrir, já busca os dados salvos
  }

  // ----------------------------------------------------------
  // PERSISTÊNCIA - ETAPA 1: CARREGAR os dados quando o app abre
  // ----------------------------------------------------------
  Future<void> carregarHabitos() async {
    // 1) Abre o armazenamento do celular (SharedPreferences).
    final prefs = await SharedPreferences.getInstance();

    // 2) Lê o texto salvo com a nossa chave. Se nunca salvou nada, vem null.
    final textoSalvo = prefs.getString(chaveArmazenamento);

    // 3) Se não tem nada salvo ainda (primeira vez), não faz nada.
    if (textoSalvo == null) return;

    // 4) Converte o texto JSON de volta em uma lista de Maps.
    final List<dynamic> listaDeMapas = jsonDecode(textoSalvo);

    // 5) Transforma cada Map em um objeto Habito e atualiza a tela.
    setState(() {
      habitos = listaDeMapas.map((m) => Habito.fromMap(m)).toList();
    });
  }

  // ----------------------------------------------------------
  // PERSISTÊNCIA - ETAPA 2: SALVAR os dados
  // Chamada sempre que a lista muda (adicionar, concluir, remover).
  // ----------------------------------------------------------
  Future<void> salvarHabitos() async {
    // 1) Abre o armazenamento do celular.
    final prefs = await SharedPreferences.getInstance();

    // 2) Transforma cada Habito em Map.
    final listaDeMapas = habitos.map((h) => h.toMap()).toList();

    // 3) Transforma a lista inteira em um único texto JSON.
    final texto = jsonEncode(listaDeMapas);

    // 4) Guarda o texto no celular usando a chave. Fica salvo mesmo
    //    depois de fechar o app.
    await prefs.setString(chaveArmazenamento, texto);
  }

  // Abre uma janelinha para o usuário escolher qual hábito quer adicionar.
  Future<void> adicionarHabito() async {
    final escolhido = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Escolha um hábito'),
          children: habitosDisponiveis.keys.map((nome) {
            return SimpleDialogOption(
              // Ao tocar, a janela fecha e devolve o nome escolhido.
              onPressed: () => Navigator.pop(context, nome),
              child: Text(nome),
            );
          }).toList(),
        );
      },
    );

    // Se o usuário fechou a janela sem escolher, não faz nada.
    if (escolhido == null) return;

    setState(() {
      habitos.add(Habito(nome: escolhido, co2: habitosDisponiveis[escolhido]!));
    });
    salvarHabitos(); // salva depois de adicionar
  }

  // Marca ou desmarca um hábito como concluído.
  void alternarConcluido(int indice) {
    setState(() {
      habitos[indice].concluido = !habitos[indice].concluido;
    });
    salvarHabitos(); // salva depois de mudar
  }

  // Remove um hábito da lista.
  void removerHabito(int indice) {
    setState(() {
      habitos.removeAt(indice);
    });
    salvarHabitos(); // salva depois de remover
  }

  // DIFERENCIAL CRIATIVO: soma o CO2 evitado só dos hábitos concluídos.
  double get totalCo2 {
    double soma = 0;
    for (final h in habitos) {
      if (h.concluido) soma += h.co2;
    }
    return soma;
  }

  // Conta quantos hábitos já foram concluídos.
  int get totalConcluidos => habitos.where((h) => h.concluido).length;

  @override
  Widget build(BuildContext context) {
    // Progresso da meta semanal (valor entre 0 e 1 para a barra).
    final progresso = (totalCo2 / metaSemanalKg).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoHábitos'),
        actions: [
          // Botão que leva para a SEGUNDA TELA (navegação).
          IconButton(
            icon: const Icon(Icons.eco),
            tooltip: 'Ver meu impacto',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaImpacto(
                    totalCo2: totalCo2,
                    totalConcluidos: totalConcluidos,
                    totalHabitos: habitos.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cartão no topo com o contador de CO2 e a barra da meta semanal.
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CO2 evitado: ${totalCo2.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Meta semanal: $metaSemanalKg kg'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progresso, minHeight: 10),
                ],
              ),
            ),
          ),
          // A lista de hábitos ocupa o resto da tela.
          Expanded(
            child: habitos.isEmpty
                ? const Center(
                    child: Text('Nenhum hábito ainda.\nToque no + para adicionar!',
                        textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    itemCount: habitos.length,
                    itemBuilder: (context, indice) {
                      final h = habitos[indice];
                      return ListTile(
                        // Caixinha para CONCLUIR o hábito.
                        leading: Checkbox(
                          value: h.concluido,
                          onChanged: (_) => alternarConcluido(indice),
                        ),
                        title: Text(
                          h.nome,
                          // Se concluído, o texto aparece riscado.
                          style: TextStyle(
                            decoration: h.concluido
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text('Evita ${h.co2} kg de CO2'),
                        // Botão de lixeira para REMOVER o hábito.
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => removerHabito(indice),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Botão flutuante para ADICIONAR um hábito.
      floatingActionButton: FloatingActionButton(
        onPressed: adicionarHabito,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ------------------------------------------------------------
// SEGUNDA TELA: resumo do impacto e dica do dia
// ------------------------------------------------------------
class TelaImpacto extends StatelessWidget {
  final double totalCo2;
  final int totalConcluidos;
  final int totalHabitos;

  const TelaImpacto({
    super.key,
    required this.totalCo2,
    required this.totalConcluidos,
    required this.totalHabitos,
  });

  @override
  Widget build(BuildContext context) {
    // DICA DO DIA: usa o dia da semana (1 a 7) para escolher uma dica da lista.
    final dica = dicas[DateTime.now().weekday - 1];

    // Comparação simples: uma árvore absorve cerca de 22 kg de CO2 por ano.
    final arvores = totalCo2 / 22;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu impacto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hábitos concluídos: $totalConcluidos de $totalHabitos',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('CO2 evitado: ${totalCo2.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Isso equivale a ${arvores.toStringAsFixed(2)} árvore(s) '
              'absorvendo CO2 durante um ano.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dica do dia',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(dica),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Botão para voltar para a tela principal.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
