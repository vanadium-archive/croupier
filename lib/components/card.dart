import '../logic/card.dart' as logic_card;
import 'package:sky/widgets.dart' as widgets;

class Card extends widgets.Component {
  logic_card.Card card;
  bool faceUp;

  Card(this.card, this.faceUp);

  widgets.Widget build() {
    return new widgets.Listener(
      child: imageFromCard(card, faceUp)
    );
  }

  static widgets.Widget imageFromCard(logic_card.Card c, bool faceUp) {
    String imageName = "${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }
}
