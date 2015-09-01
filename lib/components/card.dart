import '../logic/card.dart' as logic_card;
import 'package:sky/widgets.dart' as widgets;

class Card extends widgets.Component {
  logic_card.Card card;
  bool faceUp;

  Card(this.card, this.faceUp);

  widgets.Widget build() {
    return new widgets.Listener(child: imageFromCard(card, faceUp));
  }

  static widgets.Widget imageFromCard(logic_card.Card c, bool faceUp) {
    // TODO(alexfandrianto): If we allow an optional prefix in front of this,
    // we would be able to have multiple skins of the same deck.
    // TODO(alexfandrianto): Better card organization?
    String imageName =
        "${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }
}
