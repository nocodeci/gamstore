
import 'onboarding_info.dart';

class OnboardingItems{
  List<OnboardingInfo> items = [
    OnboardingInfo(
        title: "Toutes les compagnies, un seul site",
        descriptions: "Accédez à des dizaines de compagnies de transport en un clic, Comparez les prix, les horaires et choisissez l’option qui vous convient le mieux !",
        image: "assets/images/bus.png"),

    OnboardingInfo(
        title: "Choisissez votre siège en toute liberté",
        descriptions: "Visualisez le plan des sièges de chaque compagnie et réservez votre place préférée à l’avance. Confort garanti dès la montée à bord.",
        image: "assets/images/sieges.png"),

    OnboardingInfo(
        title: "Billet électronique instantané",
        descriptions: "Recevez votre ticket immédiatement après paiement. Scannez-le directement depuis votre téléphone, sans impression ni attente.",
        image: "assets/images/billets.png"),

    OnboardingInfo(
        title: "Trouvez l’itinéraire idéal",
        descriptions: "Indiquez votre point de départ et votre destination. Nous vous montrons les meilleurs trajets disponibles, selon votre budget, la durée ou la compagnie.",
        image: "assets/images/itineraire.png"),

  ];
}