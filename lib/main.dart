import 'package:flutter/material.dart';
import 'models/user.dart';
import 'models/cart.dart';
import 'services/dummyjson_api.dart';

void main() {
  runApp(const DummyJsonApp());
}

class DummyJsonApp extends StatelessWidget {
  const DummyJsonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DummyJSON Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

/// --- TELA DE LOGIN ---------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _api = DummyJsonApi();
  final _form = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(text: 'emilys'); // exemplo
  final _passCtrl = TextEditingController(text: 'emilyspass'); // exemplo
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.login(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(api: _api),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login • DummyJSON')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Use um usuário do /users (ex.: emilys / emilyspass)',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o user'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} // <-- Esta chave estava faltando!

/// Página principal que exibe usuários e carrinhos
class HomePage extends StatefulWidget {
  final DummyJsonApi api;

  const HomePage({super.key, required this.api});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// --- HOME: campo de texto para "N" e listas de Users/Carts ------------------
class _HomePageState extends State<HomePage> {
  // --- Filtros ---
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _selectedGender;

  // --- Quantidade (fallback para "últimos N") ---
  final _qtyCtrl = TextEditingController(text: '10');

  bool _loading = false;
  String? _error;
  List<User> _users = const [];
  List<Cart> _carts = const [];

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<User> users;

      // se filtros foram informados → usa busca avançada
      if (_nameCtrl.text.isNotEmpty ||
          _emailCtrl.text.isNotEmpty ||
          (_selectedGender != null && _selectedGender!.isNotEmpty)) {
        users = await widget.api.users.searchUsersWithFilters(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          gender: _selectedGender,
        );
      } else {
        // senão, mantém lógica antiga de "últimos N"
        final n = int.tryParse(_qtyCtrl.text.trim()) ?? 10;
        users = await widget.api.getLatestUsers(limit: n);
      }

      final carts = await widget.api.getLatestCarts(limit: 10);

      setState(() {
        _users = users;
        _carts = carts;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openCart(Cart c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cart #${c.id}'),
        content: Text(
            'Total: ${c.total} (discounted: ${c.discountedTotal})\nProducts: ${c.totalProducts}, Items: ${c.totalQuantity}'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários & Carrinhos')),
      body: Column(
        children: [
          // --- Área de Filtros ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome ou username',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gênero',
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Masculino')),
                    DropdownMenuItem(value: 'female', child: Text('Feminino')),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qtd. últimos usuários (fallback)',
                    prefixIcon: Icon(Icons.filter_1),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _fetch,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_loading) const LinearProgressIndicator(),

          // --- Lista ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text('Usuários',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._users.map((u) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              u.image != null ? NetworkImage(u.image!) : null,
                          child:
                              u.image == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u.fullName),
                        subtitle: Text('@${u.username} • ${u.email}'),
                        trailing: Text('#${u.id}'),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Carrinhos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._carts.map((c) => Card(
                      child: ListTile(
                        onTap: () => _openCart(c),
                        title: Text('Cart #${c.id} • User ${c.userId}'),
                        subtitle: Text(
                            '${c.totalProducts} prod. / ${c.totalQuantity} itens • total: ${c.total} (desc: ${c.discountedTotal})'),
                        trailing: const Icon(Icons.shopping_cart_outlined),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
