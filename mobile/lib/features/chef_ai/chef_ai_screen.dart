import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/icons/app_icon_key.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/utils/emoji_sanitizer.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
import '../../data/models/models.dart';
import '../../data/repositories/chef_ai_repository.dart';
import '../../state/cart_provider.dart';
import '../../state/settings_provider.dart';

class ChefAiScreen extends ConsumerStatefulWidget {
  const ChefAiScreen({super.key});

  @override
  ConsumerState<ChefAiScreen> createState() => _ChefAiScreenState();
}

class _ChefAiScreenState extends ConsumerState<ChefAiScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _chatCtrl = TextEditingController();
  final _dreamDishCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _chatLang = 'auto';
  bool _sendingChat = false;
  bool _composingDish = false;
  GeneratedDishSpec? _generatedDish;
  final Set<String> _checkedCustomSides = <String>{};

  late List<ChefChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _messages = [
      ChefChatMessage(
        id: 'welcome-1',
        isUser: false,
        content: ref.read(appStringsProvider).chefAiWelcome,
        timestamp: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    _dreamDishCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final prompt = (preset ?? _chatCtrl.text).trim();
    if (prompt.isEmpty || _sendingChat) return;

    final userMsg = ChefChatMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      content: prompt,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, userMsg];
      _sendingChat = true;
      if (preset == null) _chatCtrl.clear();
    });

    _scrollToBottom();

    final replyText = await ref.read(chefAiRepositoryProvider).askChef(
          history: _messages,
          prompt: prompt,
          language: _chatLang,
        );

    if (!mounted) return;
    setState(() {
      _messages = [
        ..._messages,
        ChefChatMessage(
          id: 'a-${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          content: replyText,
          timestamp: DateTime.now(),
        ),
      ];
      _sendingChat = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _generateCustomDish([String? preset]) async {
    final concept = (preset ?? _dreamDishCtrl.text).trim();
    if (concept.isEmpty || _composingDish) return;
    if (preset != null) _dreamDishCtrl.text = preset;

    setState(() => _composingDish = true);
    final spec =
        await ref.read(chefAiRepositoryProvider).designCustomDish(concept);
    if (!mounted) return;

    setState(() {
      _generatedDish = spec;
      // Transparent opt-in: nothing added behind user's back unless checked!
      _checkedCustomSides
        ..clear()
        ..addAll(spec.customizations.take(1));
      _composingDish = false;
    });
  }

  void _addGeneratedDishToCart(GeneratedDishSpec spec) {
    final chosenSides = spec.customizations
        .where((name) => _checkedCustomSides.contains(name))
        .map(
          (name) => CustomizationOption(
            id: 'ai-side-${name.toLowerCase().replaceAll(' ', '-')}',
            name: name,
            price: 1000,
          ),
        )
        .toList();

    final menuItem = MenuItemModel(
      id: 'custom-ai-${DateTime.now().millisecondsSinceEpoch}',
      name: spec.name,
      description: spec.description,
      imageUrl: spec.imageUrl,
      price: spec.price,
      calories: spec.calories,
      protein: spec.protein,
      categoryId: 'cat-gourmet',
      categoryName: spec.category,
    );

    ref.read(cartProvider.notifier).addItem(
          dish: menuItem,
          customizations: chosenSides,
          isCustomAiDish: true,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              iconKey: AppIconKey.sparkles,
              color: AppColors.surface,
            ),
            const SizedBox(width: AppSpace.v8),
            Flexible(
              child: Text(
                '${spec.name} ${ref.read(appStringsProvider).chefAiAddedToCart}',
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.v20, AppSpace.v12, AppSpace.v20, AppSpace.v8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpace.v10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.v14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.surface,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpace.v12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chef Atelier AI',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Text(
                          t.isSw
                              ? 'Mpishi Mkuu wa Kiswahili • Dar es Salaam'
                              : 'Executive Swahili Culinary Studio',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(value: 'auto', label: Text('Auto')),
                      ButtonSegment(value: 'sw', label: Text('SW')),
                      ButtonSegment(value: 'en', label: Text('EN')),
                    ],
                    selected: {_chatLang},
                    onSelectionChanged: (s) =>
                        setState(() => _chatLang = s.first),
                  ),
                ],
              ),
            ),

            // Mode Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.v16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: AppColors.clear,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.v14),
                  ),
                  labelColor: AppColors.surface,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(iconKey: AppIconKey.chat),
                          const SizedBox(width: AppSpace.v4),
                          Flexible(
                            child: Text(
                              t.isSw ? 'Ongea na Chef' : 'Chef Notes',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(iconKey: AppIconKey.soup),
                          const SizedBox(width: AppSpace.v4),
                          Flexible(
                            child: Text(
                              t.isSw ? 'Buni Sahani' : 'Dish Creator',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.v8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatTab(isDark, t.isSw),
                  _buildDishCreatorTab(isDark, t.isSw),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab(bool isDark, bool isSw) {
    final prompts = [
      'Siri ya Pilau ya Zanzibar ni nini?',
      'Best Nyama Choma combo tonight?',
      'Recommend a coconut fish dish',
      'Vipi kuhusu Chipsi Mayai special?',
    ];

    return Column(
      children: [
        SizedBox(
          height: AppSpace.v38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.v8),
            itemBuilder: (_, idx) => ActionChip(
              label: Text(
                prompts[idx],
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _sendMessage(prompts[idx]),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.v6),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.sm,
                AppSpace.screenH, context.navClearance),
            itemCount: _messages.length + (_sendingChat ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _messages.length) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpace.md),
                    child: SizedBox(
                      width: AppSpace.v22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpace.v12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? AppColors.primary
                        : (isDark ? AppColors.darkCard : AppColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.v18),
                      topRight: const Radius.circular(AppRadius.v18),
                      bottomLeft: Radius.circular(msg.isUser ? AppRadius.v18 : AppRadius.v4),
                      bottomRight: Radius.circular(msg.isUser ? AppRadius.v4 : AppRadius.v18),
                    ),
                    border: msg.isUser
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                  ),
                  child: Text(
                    // AI replies are remote/generated text; user messages are
                    // deliberately left untouched.
                    msg.isUser ? msg.content : stripEmoji(msg.content),
                    style: TextStyle(
                      color: msg.isUser ? AppColors.surface : null,
                      fontSize: 13.8,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg,
              MediaQuery.viewInsetsOf(context).bottom > 0 ? AppSpace.md : context.navClearance),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: isSw
                        ? 'Uliza Chef kuhusu mapishi au menyu...'
                        : 'Ask Chef about Swahili dishes or spices...',
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.v10),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(AppSpace.v14),
                ),
                onPressed: _sendingChat ? null : () => _sendMessage(),
                icon: const Icon(Icons.send_rounded, color: AppColors.surface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDishCreatorTab(bool isDark, bool isSw) {
    final ideas = [
      'Grilled Coconut Snapper with Plantains & Lime',
      'Smoky Beef Mishkaki Pilau Royal with Avocado',
      'Crispy Masala Zege Platter with Tamarind Pili-Pili',
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.sm, AppSpace.screenH, context.navClearance),
      children: [
        Text(
          isSw
              ? 'Elezea chakula unachotamani — Chef AI atakiunda na bei ya TZS ili uagize moja kwa moja!'
              : 'Describe your dream Swahili fusion plate — Chef AI composes a real orderable dish with nutrition & TZS pricing!',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpace.v12),
        TextField(
          controller: _dreamDishCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isSw
                ? 'Mfano: Samaki wa kuchoma mwenye tui la nazi, ndizi mzuzu na pilipili ya embe...'
                : 'e.g. Charcoal-grilled snapper in spicy coconut cream with sweet fried plantains...',
          ),
        ),
        const SizedBox(height: AppSpace.v10),
        Wrap(
          spacing: AppSpace.v8,
          runSpacing: AppSpace.v6,
          children: ideas
              .map(
                (idea) => ActionChip(
                  label: Text(idea, style: const TextStyle(fontSize: 11.5)),
                  onPressed: () => _generateCustomDish(idea),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpace.v14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _composingDish ? null : () => _generateCustomDish(),
            icon: _composingDish
                ? const SizedBox(
                    width: AppSpace.v18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: Text(
              _composingDish
                  ? 'Chef is plating your creation...'
                  : (isSw ? 'Unda Sahani Maalum' : 'Compose Custom Dish'),
            ),
          ),
        ),

        if (_generatedDish != null) ...[
          const SizedBox(height: AppSpace.v20),
          Container(
            padding: const EdgeInsets.all(AppSpace.v18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.v24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.45),
                width: 1.4,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DishImage(
                      imageRef: _generatedDish!.imageUrl,
                      width: 84,
                      height: 84,
                      borderRadius: AppRadius.v18,
                    ),
                    const SizedBox(width: AppSpace.v14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm, vertical: AppSpace.v3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon(
                                  iconKey: AppIconKey.sparkles,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpace.v6),
                                Flexible(
                                  child: Text(
                                    '${ref.read(appStringsProvider).chefAiBespoke} • ${_generatedDish!.category}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.v6),
                          Text(
                            _generatedDish!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: AppSpace.v4),
                          Text(
                            '${AppStrings.formatTzs(_generatedDish!.price)} base • ${_generatedDish!.calories} kcal • ${_generatedDish!.protein}g protein',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.v12),
                Text(
                  _generatedDish!.description,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: AppSpace.v14),
                const Text(
                  'Optional Chef Sides (+TSh 1,000 each):',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                const SizedBox(height: AppSpace.v8),
                Wrap(
                  spacing: AppSpace.v8,
                  runSpacing: AppSpace.v6,
                  children: _generatedDish!.customizations.map((side) {
                    final checked = _checkedCustomSides.contains(side);
                    return FilterChip(
                      selected: checked,
                      selectedColor: AppColors.primary.withOpacity(0.18),
                      label: Text('$side (+TSh 1,000)'),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _checkedCustomSides.add(side);
                          } else {
                            _checkedCustomSides.remove(side);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpace.v16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addGeneratedDishToCart(_generatedDish!),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      'Order Custom Dish • ${AppStrings.formatTzs(_generatedDish!.price + (_checkedCustomSides.length * 1000))}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
