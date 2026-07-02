import 'dart:async';

import 'package:flutter/material.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/services/photon_service.dart';

/// Búsqueda de dirección con autocomplete Photon para el dashboard de riesgo.
/// Al seleccionar una sugerencia, notifica [onAddressSelected] con sus
/// coordenadas para que el caller dispare `RiskRequested` en el `RiskBloc`.
class RiskAddressSearch extends StatefulWidget {
  const RiskAddressSearch({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.onAddressSelected,
  });

  final double userLat;
  final double userLng;
  final ValueChanged<PhotonSuggestion> onAddressSelected;

  @override
  State<RiskAddressSearch> createState() => _RiskAddressSearchState();
}

class _RiskAddressSearchState extends State<RiskAddressSearch> {
  final _controller = TextEditingController();
  final _photon = PhotonService();
  Timer? _debounce;
  List<PhotonSuggestion> _suggestions = [];
  bool _searching = false;
  bool _noResults = false;
  bool _networkError = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _noResults = false;
        _networkError = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() {
        _searching = true;
        _noResults = false;
        _networkError = false;
      });
      final result = await _photon.suggest(
        value,
        lat: widget.userLat,
        lng: widget.userLng,
      );
      if (!mounted) return;
      switch (result) {
        case PhotonSuccess(:final suggestions):
          setState(() {
            _searching = false;
            _suggestions = suggestions;
            _noResults = suggestions.isEmpty;
            _networkError = false;
          });
        case PhotonNetworkError():
          setState(() {
            _searching = false;
            _suggestions = [];
            _noResults = false;
            _networkError = true;
          });
      }
    });
  }

  void _onSuggestionTap(PhotonSuggestion suggestion) {
    _controller.text = suggestion.displayName;
    setState(() {
      _suggestions = [];
      _noResults = false;
      _networkError = false;
    });
    FocusScope.of(context).unfocus();
    widget.onAddressSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    decoration: const InputDecoration(
                      hintText: 'Buscar una dirección…',
                      hintStyle: AppTextStyles.bodyMd,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: AppTextStyles.bodyLg,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_searching)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.search,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surfaceContainerHigh,
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 16,
                color: AppColors.outlineVariant,
              ),
              itemBuilder: (context, i) {
                final suggestion = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    suggestion.displayName,
                    style: AppTextStyles.bodyMd,
                  ),
                  onTap: () => _onSuggestionTap(suggestion),
                );
              },
            ),
          ),
        ],
        if (_noResults) ...[
          const SizedBox(height: 8),
          Text(
            'No encontramos esa dirección',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (_networkError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'No pudimos buscar direcciones. Revisá tu conexión.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
