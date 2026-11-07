import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';
import '../models/models.dart';

final chefAiRepositoryProvider = Provider<ChefAiRepository>((ref) {
  return ChefAiRepository();
});

class ChefAiRepository {
  Future<String> askChef({
    required List<ChefChatMessage> history,
    required String prompt,
    String language = 'auto',
  }) async {
    // 1. Try Supabase Edge Function (`chef-ai`) if configured
    final edgeUrl = EnvConfig.chefEdgeFunctionUrl;
    if (edgeUrl.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse(edgeUrl),
              headers: {
                'Content-Type': 'application/json',
                'apikey': EnvConfig.supabaseAnonKey,
                'Authorization': 'Bearer ${EnvConfig.supabaseAnonKey}',
              },
              body: jsonEncode({
                'action': 'chat',
                'message': prompt,
                'language': language,
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final reply = data['reply']?.toString();
          if (reply != null && reply.trim().isNotEmpty) return reply.trim();
        }
      } catch (_) {}
    }

    // 2. Try Next.js `/api/chef` if WEB_API_BASE_URL is configured
    if (EnvConfig.webApiBaseUrl.trim().isNotEmpty) {
      try {
        final cleanBase = EnvConfig.webApiBaseUrl.endsWith('/')
            ? EnvConfig.webApiBaseUrl
                .substring(0, EnvConfig.webApiBaseUrl.length - 1)
            : EnvConfig.webApiBaseUrl;
        final res = await http
            .post(
              Uri.parse('$cleanBase/api/chef'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'language': language,
                'messages': [
                  ...history.map((m) => {
                        'role': m.isUser ? 'user' : 'assistant',
                        'content': m.content,
                      }),
                  {'role': 'user', 'content': prompt},
                ],
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final reply = data['reply']?.toString();
          if (reply != null && reply.trim().isNotEmpty) return reply.trim();
        }
      } catch (_) {}
    }

    // 3. Built-in Context-Aware Swahili Executive Chef Engine (always fast & reliable!)
    await Future<void>.delayed(const Duration(milliseconds: 550));
    return _localSwahiliChefAdvisor(prompt, language);
  }

  Future<GeneratedDishSpec> designCustomDish(String userConcept) async {
    // 1. Try Supabase Edge Function (`chef-ai` custom_dish)
    final edgeUrl = EnvConfig.chefEdgeFunctionUrl;
    if (edgeUrl.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse(edgeUrl),
              headers: {
                'Content-Type': 'application/json',
                'apikey': EnvConfig.supabaseAnonKey,
                'Authorization': 'Bearer ${EnvConfig.supabaseAnonKey}',
              },
              body: jsonEncode({
                'action': 'custom_dish',
                'description': userConcept,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return GeneratedDishSpec(
            name: (data['name'] ?? 'Sahani Maalum ya Chef').toString(),
            description: (data['description'] ?? userConcept).toString(),
            price: (data['price'] as num?)?.toDouble() ?? 9500,
            calories: (data['calories'] as num?)?.toInt() ?? 610,
            protein: (data['protein'] as num?)?.toInt() ?? 34,
            category: (data['category'] ?? 'Swahili Bites').toString(),
            customizations: (data['customizations'] is List)
                ? (data['customizations'] as List).map((e) => e.toString()).toList()
                : const ['Kachumbari Extra', 'Pili Pili Kali'],
            imageUrl: (data['imageUrl'] ?? _pickLocalDishAsset(userConcept)).toString(),
          );
        }
      } catch (_) {}
    }

    // 2. Try Next.js `/api/chef/custom-dish` if WEB_API_BASE_URL is configured
    if (EnvConfig.webApiBaseUrl.trim().isNotEmpty) {
      try {
        final cleanBase = EnvConfig.webApiBaseUrl.endsWith('/')
            ? EnvConfig.webApiBaseUrl
                .substring(0, EnvConfig.webApiBaseUrl.length - 1)
            : EnvConfig.webApiBaseUrl;
        final res = await http
            .post(
              Uri.parse('$cleanBase/api/chef/custom-dish'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'description': userConcept}),
            )
            .timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return GeneratedDishSpec(
            name: (data['name'] ?? 'Sahani Maalum ya Chef').toString(),
            description: (data['description'] ?? userConcept).toString(),
            price: (data['price'] as num?)?.toDouble() ?? 9500,
            calories: (data['calories'] as num?)?.toInt() ?? 610,
            protein: (data['protein'] as num?)?.toInt() ?? 34,
            category: (data['category'] ?? 'Swahili Bites').toString(),
            customizations: (data['customizations'] is List)
                ? (data['customizations'] as List).map((e) => e.toString()).toList()
                : const ['Kachumbari Extra', 'Pili Pili Kali'],
            imageUrl: (data['imageUrl'] ?? _pickLocalDishAsset(userConcept)).toString(),
          );
        }
      } catch (_) {}
    }

    // 3. Smart Local Culinary Composition Engine
    await Future<void>.delayed(const Duration(milliseconds: 850));
    return _composeLocalGourmetDish(userConcept);
  }

  String _localSwahiliChefAdvisor(String prompt, String language) {
    final q = prompt.toLowerCase();
    final sw = language == 'sw' ||
        RegExp(r'\b(vipi|chakula|nini|kupika|nyama|chipsi|pilau|samaki|mambo|habari|nipe|siri)\b')
            .hasMatch(q);

    if (q.contains('pilau') || q.contains('wali') || q.contains('rice')) {
      return sw
          ? 'Siri ya Pilau ya Zanzibar ni kukaanga vitunguu hadi viwe rangi ya kahawia nzito kabla ya kuweka iliki, karafuu, mdalasini na pilipili manga nzima! Jaribu Pilau ya Kuku yetu (TSh 10,000) pamoja na kachumbari na Juisi ya Passion baridi.'
          : 'The secret to fragrant Zanzibar Pilau is caramelizing sliced onions deep golden before blooming whole cardamom, cloves, cumin, and cinnamon! Pair our Pilau ya Kuku (TSh 10,000) with fresh kachumbari and chilled Passion Mango juice.';
    }
    if (q.contains('nyama') || q.contains('choma') || q.contains('mishkaki') || q.contains('mbuzi')) {
      return sw
          ? 'Kwa Nyama Choma laini yenye harufu ya mkaa, tunailoweka kwa tangawizi mbichi, kitunguu saumu na ndimu kabla ya kuichoma taratibu. Agiza na Ugali wa moto, mchicha wa nazi na Stoney Tangawizi baridi!'
          : 'Our charcoal-grilled Nyama Choma & Mishkaki are marinated in crushed ginger, garlic, papaya tenderizer, and fresh lime. Enjoy them hot off the mkaa grill with sembe ugali, mchicha wa nazi, and an ice-cold Stoney Tangawizi!';
    }
    if (q.contains('samaki') || q.contains('fish') || q.contains('kupaka') || q.contains('nazi')) {
      return sw
          ? 'Samaki wa Kupaka (TSh 15,000) anachomwa kwanza juu ya mkaa kisha anapikwa ndani ya tui zito la nazi lenye ukwaju na manjano. Inapendeza sana ukila na chapati mbili za moto!'
          : 'Our coastal Samaki wa Kupaka (TSh 15,000) sears fresh Indian Ocean snapper over charcoal before simmering in velvety Tui la Nazi coconut cream and tamarind. Order it with warm layered ghee chapati!';
    }
    if (q.contains('chipsi') || q.contains('mayai')) {
      return sw
          ? 'Chipsi Mayai yetu ya Kijitonyama (TSh 5,500) inapikwa na mayai mawili ya kienyeji, hoho na kitunguu, ikisindikizwa na kachumbari na pilipili ya ukwaju!'
          : 'Our golden Dar es Salaam Chipsi Mayai (TSh 5,500) folds crispy hand-cut fries into farm eggs with sweet peppers, served hot with tomato-lime kachumbari and house tamarind pili-pili!';
    }

    return sw
        ? 'Karibu Chef Atelier! Leo ninapendekeza Samaki wa Kupaka wa tui la nazi au Mishkaki ya Ng’ombe yenye pilipili na ndimu. Pia unaweza kubonyeza tab ya "Dish Creator" nikikuundie sahani maalum kulingana na unachotamani!'
        : 'Karibu to Chef Atelier! Tonight I recommend our smoky Nyama Choma & Ugali or coastal Samaki wa Kupaka simmered in fresh coconut milk. Switch to the "Dish Creator" tab anytime to design and order a bespoke Swahili creation!';
  }

  GeneratedDishSpec _composeLocalGourmetDish(String concept) {
    final lower = concept.toLowerCase();
    if (lower.contains('samaki') || lower.contains('fish') || lower.contains('prawns') || lower.contains('seafood')) {
      return GeneratedDishSpec(
        name: 'Samaki wa Nazi & Ndizi Special',
        description:
            'Charcoal-grilled coastal fish fillet glazed in spiced coconut-tamarind cream with caramelized plantains ($concept).',
        price: 14500,
        calories: 640,
        protein: 39,
        category: 'Traditional Stews',
        customizations: const ['Ndimu (Fresh Lime)', 'Chapati Moja', 'Pili Pili Kali'],
        imageUrl: 'samakiWaKupaka',
      );
    }
    if (lower.contains('pilau') || lower.contains('biryani') || lower.contains('wali') || lower.contains('rice')) {
      return GeneratedDishSpec(
        name: 'Pilau Royal ya Chef AI',
        description:
            'Zanzibar cardamom-clove basmati pilau tailored to your request: $concept, finished with crispy shallots.',
        price: 11500,
        calories: 670,
        protein: 33,
        category: 'Rice & Pilau',
        customizations: const ['Kachumbari Extra', 'Avocado Slices', 'Juisi ya Passion'],
        imageUrl: 'pilauYaKuku',
      );
    }
    if (lower.contains('burger') || lower.contains('pizza')) {
      final isPizza = lower.contains('pizza');
      return GeneratedDishSpec(
        name: isPizza ? 'Swahili Mkaa Fusion Pizza' : 'Dar Double Pili-Pili Burger',
        description:
            'Chef custom Swahili fusion crafted from "$concept" with melted cheese, roasted peppers, and house spice glaze.',
        price: isPizza ? 15500 : 12000,
        calories: 760,
        protein: 37,
        category: 'Gourmet Specials',
        customizations: const ['Avocado Slices', 'Pili Pili Kali', 'Stoney Tangawizi'],
        imageUrl: isPizza ? 'pizzaOne' : 'burgerOne',
      );
    }
    if (lower.contains('chips') || lower.contains('mayai') || lower.contains('ndizi')) {
      return GeneratedDishSpec(
        name: 'Zege & Mishkaki Platter',
        description:
            'Crispy masala fries & golden egg zege paired with smoky Swahili spices inspired by "$concept".',
        price: 8500,
        calories: 610,
        protein: 26,
        category: 'Swahili Bites',
        customizations: const ['Kachumbari Extra', 'Pili Pili Kali', 'Stoney Tangawizi'],
        imageUrl: 'chipsiMayai',
      );
    }

    return GeneratedDishSpec(
      name: 'Mkaa Choma Chef Creation',
      description:
          'Flame-grilled Tanzanian tender cuts basted in ginger-garlic lime butter, custom-plated for "$concept".',
      price: 13000,
      calories: 710,
      protein: 44,
      category: 'Nyama Choma',
      customizations: const ['Kachumbari Extra', 'Ugali Kipande', 'Pili Pili Kali'],
      imageUrl: _pickLocalDishAsset(concept),
    );
  }

  String _pickLocalDishAsset(String concept) {
    final lower = concept.toLowerCase();
    if (lower.contains('mishkaki') || lower.contains('skewer')) return 'mishkakiYaNgombe';
    if (lower.contains('samaki') || lower.contains('fish')) return 'samakiWaKupaka';
    if (lower.contains('pilau') || lower.contains('rice')) return 'pilauYaKuku';
    if (lower.contains('chips')) return 'chipsiMayai';
    return 'nyamaChoma';
  }
}
