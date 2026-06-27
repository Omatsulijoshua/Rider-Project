import 'package:flutter/material.dart';
import 'package:rider/service/backend_auth_service.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  // KYC Status: 'pending', 'approved', 'rejected'
  String _kycStatus = 'pending'; // TODO: Load from database
  DateTime? _submissionDate;
  String? _rejectionReason;

  bool _idDocumentSelected = false;
  bool _proofOfAddressSelected = false;
  bool _proofOfPhoneSelected = false;

  bool _isSubmitting = false;
  final BackendAuthService _authService = BackendAuthService();

  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
    _submissionDate = DateTime.now().subtract(const Duration(days: 2));
  }

  /// Load KYC status from backend
  Future<void> _loadKYCStatus() async {
    try {
      final result = await _authService.getKYCStatus();
      if (result['success'] == true && mounted) {
        setState(() {
          _kycStatus = result['status'] ?? 'pending';
          if (result['data'] != null) {
            _submissionDate = result['data']['submissionDate'] != null
                ? DateTime.parse(result['data']['submissionDate'])
                : null;
            _rejectionReason = result['data']['rejectionReason'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading KYC status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KYC Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),
            // KYC Status Info
            _buildStatusInfo(),
            const SizedBox(height: 24),
            // Document Upload Section
            if (_kycStatus == 'pending') ...[
              Text(
                'Required Documents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadField(
                'ID Document',
                'Valid passport, driver\'s license, or national ID',
                Icons.credit_card,
                _idDocumentSelected,
                () => _selectDocument('ID Document'),
              ),
              const SizedBox(height: 12),
              _buildDocumentUploadField(
                'Proof of Address',
                'Recent utility bill, rental agreement, or bank statement',
                Icons.home,
                _proofOfAddressSelected,
                () => _selectDocument('Proof of Address'),
              ),
              const SizedBox(height: 12),
              _buildDocumentUploadField(
                'Proof of Phone',
                'Phone bill or SIM card registration document',
                Icons.phone,
                _proofOfPhoneSelected,
                () => _selectDocument('Proof of Phone'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _allDocumentsSelected() ? _submitKYC : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Submit KYC Verification'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (_kycStatus == 'approved') ...[
              // Approved Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'KYC Verified',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your account has been verified on ${_formatDate(_submissionDate)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildVerifiedDocumentsList(),
            ] else if (_kycStatus == 'rejected') ...[
              // Rejected Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cancel,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'KYC Verification Rejected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: $_rejectionReason',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitKYCAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resubmit KYC Verification'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_kycStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 40, color: statusColor),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is KYC Verification?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Know Your Customer (KYC) is a verification process that ensures the security of our platform. We need to verify your identity before you can use our services.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 16),
        _buildInfoBullet('Protects your account from unauthorized access'),
        _buildInfoBullet('Ensures safe transactions'),
        _buildInfoBullet('Complies with regulatory requirements'),
        _buildInfoBullet('Takes about 24 hours to verify'),
      ],
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadField(
    String title,
    String description,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              )
            else
              Icon(
                Icons.file_upload_outlined,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedDocumentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verified Documents',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _buildDocumentListItem(
          'ID Document',
          'Valid passport, driver\'s license, or national ID',
          Icons.credit_card,
          true,
        ),
        const SizedBox(height: 8),
        _buildDocumentListItem(
          'Proof of Address',
          'Recent utility bill, rental agreement, or bank statement',
          Icons.home,
          true,
        ),
        const SizedBox(height: 8),
        _buildDocumentListItem(
          'Proof of Phone',
          'Phone bill or SIM card registration document',
          Icons.phone,
          true,
        ),
      ],
    );
  }

  Widget _buildDocumentListItem(
    String title,
    String description,
    IconData icon,
    bool isVerified,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isVerified ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: isVerified ? Colors.green : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  bool _allDocumentsSelected() {
    return _idDocumentSelected &&
        _proofOfAddressSelected &&
        _proofOfPhoneSelected;
  }

  void _selectDocument(String documentType) {
    // TODO: Implement file picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selecting $documentType...')),
    );

    setState(() {
      if (documentType == 'ID Document') {
        _idDocumentSelected = true;
      } else if (documentType == 'Proof of Address') {
        _proofOfAddressSelected = true;
      } else if (documentType == 'Proof of Phone') {
        _proofOfPhoneSelected = true;
      }
    });
  }

  void _submitKYC() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Show submission notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitting KYC verification...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      // Submit KYC documents to backend
      final result = await _authService.submitKYC(
        idDocument: _idDocumentSelected ? 'id_document_path' : '',
        proofOfAddress: _proofOfAddressSelected ? 'proof_of_address_path' : '',
        proofOfPhone: _proofOfPhoneSelected ? 'proof_of_phone_path' : '',
      );

      // Check if widget is still mounted before updating UI
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _kycStatus = 'pending';
          _submissionDate = DateTime.now();
          _isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'KYC submitted successfully! We will review and notify you within 24 hours.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit KYC'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      debugPrint('Error submitting KYC: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting KYC: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _submitKYCAgain() {
    setState(() {
      _idDocumentSelected = false;
      _proofOfAddressSelected = false;
      _proofOfPhoneSelected = false;
      _kycStatus = 'pending';
      _rejectionReason = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please resubmit your documents'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
