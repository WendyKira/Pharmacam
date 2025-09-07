import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModePaiementPage extends StatefulWidget {
  const ModePaiementPage({Key? key}) : super(key: key);

  @override
  State<ModePaiementPage> createState() => _ModePaiementPageState();
}

class _ModePaiementPageState extends State<ModePaiementPage>
    with TickerProviderStateMixin {
  String? selectedPaymentMethod;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'orange_money',
      name: 'Orange Money',
      icon: Icons.phone_android,
      color: const Color(0xFFFF6B35),
      route: '/om',
    ),
    PaymentMethod(
      id: 'mtn_mobile_money',
      name: 'MTN Mobile Money',
      icon: Icons.smartphone,
      color: const Color(0xFFFFD60A),
      route: '/momo',
    ),
    PaymentMethod(
      id: 'paypal',
      name: 'PayPal',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF0070BA),
      route: '/paypal',
    ),
    PaymentMethod(
      id: 'carte_de_credit',
      name: 'Carte de Crédit',
      icon: Icons.credit_card,
      color: const Color(0xFF1A1F71),
      route: '/form',
    ),
    PaymentMethod(
      id: 'transfert_bancaire',
      name: 'Virement Bancaire',
      icon: Icons.account_balance,
      color: const Color(0xFF2E8B57),
      route: '/bank',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectPaymentMethod(String methodId) {
    setState(() {
      selectedPaymentMethod = methodId;
    });

    // Feedback haptique
    HapticFeedback.lightImpact();

    // Animation de sélection
    _animationController.reset();
    _animationController.forward();
  }

  void _confirmPayment() {
    if (selectedPaymentMethod == null) return;

    // Afficher un feedback de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Mode de paiement confirmé',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28a745),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Navigation selon le mode de paiement sélectionné
    final selectedMethod = paymentMethods.firstWhere(
          (method) => method.id == selectedPaymentMethod,
    );

    // Ici vous pouvez implémenter la navigation
    // Navigator.pushNamed(context, selectedMethod.route);
    Navigator.pushNamed(context, selectedMethod.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PHARMACAM',
          style: TextStyle(
            color: Color(0xFF28a745),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
            onPressed: () {
              // Afficher l'aide
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // En-tête avec titre et sous-titre
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28a745).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: const Color(0xFF28a745),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choisissez votre',
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Text(
                    'Mode de Paiement',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez la méthode qui vous convient',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Grille des options de paiement
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = paymentMethods[index];
                    final isSelected = selectedPaymentMethod == method.id;

                    return PaymentMethodCard(
                      method: method,
                      isSelected: isSelected,
                      onTap: () => _selectPaymentMethod(method.id),
                      animationDelay: index * 100,
                    );
                  },
                ),
              ),
            ),

            // Bouton de confirmation
            Container(
              padding: const EdgeInsets.all(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedPaymentMethod != null ? _confirmPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28a745),
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: selectedPaymentMethod != null ? 8 : 0,
                    shadowColor: const Color(0xFF28a745).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selectedPaymentMethod != null) ...[
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        selectedPaymentMethod != null
                            ? 'Confirmer le Paiement'
                            : 'Sélectionnez un Mode',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodCard extends StatefulWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;
  final int animationDelay;

  const PaymentMethodCard({
    Key? key,
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  }) : super(key: key);

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<PaymentMethodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Animation d'entrée avec délai
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.method.color
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isSelected
                          ? widget.method.color.withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: widget.isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône avec animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? widget.method.color.withOpacity(0.15)
                            : widget.method.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        widget.method.icon,
                        size: 32,
                        color: widget.method.color,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nom de la méthode
                    Text(
                      widget.method.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected
                            ? widget.method.color
                            : const Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Indicateur de sélection
                    AnimatedOpacity(
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.method.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sélectionné',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Model pour les méthodes de paiement
class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String route;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.route,
  });
}

// Import nécessaire pour le feedback haptique
