import { useCartStore } from "@/store/cart.store";
import { CartItemType } from "@/type";
import { Image, Text, TouchableOpacity, View } from "react-native";
import { images } from "@/constants";

const CartItem = ({ item }: { item: CartItemType }) => {
    const { increaseQty, decreaseQty, removeItem } = useCartStore();

    const localImgKey = item.image_url as keyof typeof images;
    const isLocalAsset = images[localImgKey] !== undefined;
    const source = isLocalAsset 
        ? images[localImgKey] 
        : (item.image_url && (item.image_url.startsWith('http://') || item.image_url.startsWith('https://') || item.image_url.startsWith('/')))
            ? { uri: item.image_url }
            : images.salad;

    return (
        <View className="cart-item">
            <View className="flex flex-row items-center gap-x-3">
                <View className="cart-item__image">
                    <Image
                        source={source}
                        className="size-[90%] rounded-lg"
                        resizeMode="contain"
                    />
                </View>

                <View>
                    <Text className="base-bold text-gourmet-charcoal">{item.name}</Text>
                    
                    {item.isAICreated && (
                        <Text className="text-[9px] font-mono text-gourmet-amber mt-0.5 tracking-wider uppercase">
                            AI Custom • {item.calories} kcal
                        </Text>
                    )}

                    <Text className="paragraph-bold text-gourmet-forest mt-1">
                        TSh {item.price.toLocaleString()}
                    </Text>

                    <View className="flex flex-row items-center gap-x-4 mt-2">
                        <TouchableOpacity
                            onPress={() => decreaseQty(item.id, item.customizations!)}
                            className="cart-item__actions"
                        >
                            <Image
                                source={images.minus}
                                className="size-1/2"
                                resizeMode="contain"
                                tintColor={"#F6821F"}
                            />
                        </TouchableOpacity>

                        <Text className="base-bold text-gourmet-charcoal">{item.quantity}</Text>

                        <TouchableOpacity
                            onPress={() => increaseQty(item.id, item.customizations!)}
                            className="cart-item__actions"
                        >
                            <Image
                                source={images.plus}
                                className="size-1/2"
                                resizeMode="contain"
                                tintColor={"#F6821F"}
                            />
                        </TouchableOpacity>
                    </View>
                </View>
            </View>

            <TouchableOpacity
                onPress={() => removeItem(item.id, item.customizations!)}
                className="flex-center"
            >
                <Image source={images.trash} className="size-5" resizeMode="contain" tintColor="#787774" />
            </TouchableOpacity>
        </View>
    );
};

export default CartItem;
