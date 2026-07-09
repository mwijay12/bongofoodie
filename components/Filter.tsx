import { View, Text, FlatList, TouchableOpacity, Platform } from 'react-native'
import { Category } from "@/type";
import { router, useLocalSearchParams } from "expo-router";
import { useState } from "react";
import cn from "clsx";

const Filter = ({ categories }: { categories: Category[] }) => {
    const searchParams = useLocalSearchParams();
    const [active, setActive] = useState<string>((searchParams.category as string) || '');

    const handlePress = (id: string) => {
        setActive(id);

        if (id === 'all') router.setParams({ category: undefined });
        else router.setParams({ category: id });
    };

    const filterData: (Category | { $id: string; name: string })[] = categories
        ? [{ $id: 'all', name: 'All' }, ...categories]
        : [{ $id: 'all', name: 'All' }]

    return (
        <FlatList
            data={filterData}
            keyExtractor={(item: Category | { $id: string; name: string }) => item.$id}
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerClassName="gap-x-2 pb-3"
            renderItem={({ item }: { item: Category | { $id: string; name: string } }) => {
                const isActive = active === item.$id || (item.$id === 'all' && !active);
                return (
                    <TouchableOpacity
                        key={item.$id}
                        className={cn('filter py-2 px-4 rounded-lg', isActive ? 'bg-gourmet-forest border-gourmet-forest' : 'bg-white border border-gourmet-border')}
                        onPress={() => handlePress(item.$id)}
                    >
                        <Text className={cn('paragraph-bold', isActive ? 'text-white' : 'text-gourmet-charcoal')}>
                            {item.name}
                        </Text>
                    </TouchableOpacity>
                );
            }}
        />
    )
}
export default Filter
