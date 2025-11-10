import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/receipt_bloc.dart';
import '../widgets/receipt_card.dart';
import '../design_system/components/molecules/tb_dialog.dart';
import '../design_system/colors/tb_colors.dart';
import '../design_system/typography/tb_typography.dart';

class ReceiptListScreen extends StatelessWidget {
  const ReceiptListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReceiptBloc()..add(LoadReceipts()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Comprobantes de Pago', style: TBTypography.headlineMedium),
          backgroundColor: TBColors.primary,
          foregroundColor: TBColors.white,
        ),
        body: BlocBuilder<ReceiptBloc, ReceiptState>(
          builder: (context, state) {
            if (state is ReceiptLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is ReceiptError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                TBDialogHelper.showError(
                  context,
                  title: 'Error al cargar',
                  message: 'No se pudieron cargar los comprobantes. ${state.message}',
                  buttonText: 'Reintentar',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<ReceiptBloc>().add(LoadReceipts());
                  },
                );
              });
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is ReceiptLoaded) {
              return ListView.builder(
                itemCount: state.receipts.length,
                itemBuilder: (context, index) {
                  final receipt = state.receipts[index];
                  return ReceiptCard(
                    receipt: receipt,
                    onDownloadPdf: () {
                      context.read<ReceiptBloc>().add(GeneratePdf(receipt));
                    },
                  );
                },
              );
            }
            
            return const SizedBox();
          },
        ),
      ),
    );
  }
}