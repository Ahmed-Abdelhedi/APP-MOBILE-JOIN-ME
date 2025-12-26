import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final double? paymentAmount;
  final String? activityTitle;
  
  const PaymentMethodsScreen({
    super.key,
    this.paymentAmount,
    this.activityTitle,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String? _selectedPaymentMethod;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'card',
      'icon': Icons.credit_card,
      'name': 'Visa',
      'number': '**** **** **** 4532',
      'expiry': '12/25',
      'isDefault': true,
    },
    {
      'type': 'card',
      'icon': Icons.credit_card,
      'name': 'Mastercard',
      'number': '**** **** **** 8790',
      'expiry': '03/26',
      'isDefault': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isPaymentMode = widget.paymentAmount != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isPaymentMode ? 'Confirmer le paiement' : 'Paiements'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isPaymentMode ? Icons.payment : Icons.credit_card,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  isPaymentMode ? 'Paiement' : 'Méthodes de paiement',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (isPaymentMode) ...[
                  Text(
                    widget.activityTitle ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.paymentAmount!.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else
                  const Text(
                    'Gérez vos cartes et moyens de paiement',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payment instruction for payment mode
          if (isPaymentMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sélectionnez une méthode de paiement pour confirmer votre participation',
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Mes cartes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes cartes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                TextButton.icon(
                  onPressed: _addPaymentMethod,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),

          // Liste des cartes
          ..._paymentMethods.map((method) => _buildPaymentCard(method)),

          const SizedBox(height: 24),

          // Confirm payment button (only in payment mode)
          if (isPaymentMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod != null
                    ? () {
                        // Show processing dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Traitement du paiement...'),
                              ],
                            ),
                          ),
                        );
                        
                        // Simulate payment processing
                        Future.delayed(const Duration(seconds: 2), () {
                          Navigator.of(context).pop(); // Close processing dialog
                          
                          // Show success dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.check_circle, 
                                    color: Colors.green, 
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Paiement réussi'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Montant: ${widget.paymentAmount!.toStringAsFixed(2)}€'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Votre participation à "${widget.activityTitle}" est confirmée!',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close success dialog
                                    Navigator.of(context).pop(true); // Return to home with success
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  _selectedPaymentMethod != null
                      ? 'Confirmer le paiement de ${widget.paymentAmount!.toStringAsFixed(2)}€'
                      : 'Sélectionnez une méthode de paiement',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          if (!isPaymentMode) ...[
            const SizedBox(height: 24),

            // Autres moyens de paiement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Autres moyens',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),

          _buildPaymentOption(
            icon: Icons.account_balance,
            title: 'Virement bancaire',
            subtitle: 'Payer par virement',
            onTap: () {
              _showComingSoonDialog('Virement bancaire');
            },
          ),

          _buildPaymentOption(
            icon: Icons.wallet,
            title: 'PayPal',
            subtitle: 'Connecter votre compte PayPal',
            onTap: () {
              _showComingSoonDialog('PayPal');
            },
          ),

          _buildPaymentOption(
            icon: Icons.phone_android,
            title: 'Apple Pay / Google Pay',
            subtitle: 'Paiement mobile',
            onTap: () {
              _showComingSoonDialog('Paiement mobile');
            },
          ),

          const SizedBox(height: 24),

          // Historique des transactions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Historique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),

          _buildTransactionItem(
            title: 'Cours de Yoga',
            amount: '-15.00€',
            date: '25 Nov 2025',
            icon: Icons.fitness_center,
            isPositive: false,
          ),

          _buildTransactionItem(
            title: 'Soirée Gaming',
            amount: '-10.00€',
            date: '20 Nov 2025',
            icon: Icons.sports_esports,
            isPositive: false,
          ),

          _buildTransactionItem(
            title: 'Remboursement',
            amount: '+15.00€',
            date: '15 Nov 2025',
            icon: Icons.refresh,
            isPositive: true,
          ),

          const SizedBox(height: 16),

          // Info sécurité
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vos informations bancaires sont cryptées et sécurisées.',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          ], // End of if (!isPaymentMode)
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> method) {
    final isPaymentMode = widget.paymentAmount != null;
    final isSelected = _selectedPaymentMethod == method['id'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isPaymentMode ? () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        } : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isPaymentMode)
                Radio<String>(
                  value: method['id'],
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  method['icon'],
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          method['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (method['isDefault']) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Par défaut',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['number'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Expire: ${method['expiry']}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPaymentMode)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                  if (!method['isDefault'])
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Définir par défaut'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'default') {
                    _setAsDefault(method);
                  } else if (value == 'edit') {
                    _editPaymentMethod(method);
                  } else if (value == 'delete') {
                    _deletePaymentMethod(method);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String amount,
    required String date,
    required IconData icon,
    required bool isPositive,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
        child: Icon(
          icon,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une carte'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Numéro de carte',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Expiration',
                        hintText: 'MM/AA',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carte ajoutée avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(Map<String, dynamic> method) {
    setState(() {
      for (var m in _paymentMethods) {
        m['isDefault'] = false;
      }
      method['isDefault'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method['name']} définie par défaut'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editPaymentMethod(Map<String, dynamic> method) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de modification à venir'),
      ),
    );
  }

  void _deletePaymentMethod(Map<String, dynamic> method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la carte'),
        content: Text(
          'Voulez-vous vraiment supprimer ${method['name']} ${method['number']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentMethods.remove(method);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carte supprimée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bientôt disponible'),
        content: Text('$feature sera disponible dans une prochaine mise à jour.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
